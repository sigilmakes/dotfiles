#!/usr/bin/env python3
"""
Automatic night mode daemon for hyprsunset.

Calculates sunrise/sunset using the NOAA solar position algorithm,
then smoothly interpolates screen colour temperature between day and
night across a configurable transition window.

Features:
  - Location-aware sunrise/sunset (default: Warrington, UK)
  - Smooth temperature transitions via hyprsunset IPC
  - SIGUSR1 toggle (Super+N keybind)
  - System tray icon via StatusNotifierItem (D-Bus)
  - User-editable config at ~/.config/nightmode/config

Config: ~/.config/nightmode/config (created on first run)
Toggle: send SIGUSR1 or click the tray icon
"""

import asyncio
import configparser
import math
import os
import signal
import subprocess
import sys
from datetime import datetime, time, timedelta, timezone
from pathlib import Path

# --- Defaults ---
DEFAULTS = {
    "latitude": "53.39",
    "longitude": "-2.60",
    "temp_day": "6500",
    "temp_night": "4500",
    "transition_minutes": "45",
    "interval": "30",
}

# --- State ---
forced_off = False
last_temp = None
config = {}
tray = None  # set when tray is running


# =====================================================================
#  Configuration
# =====================================================================

def load_config() -> dict:
    """Load config from ~/.config/nightmode/config, creating defaults if missing."""
    config_dir = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "nightmode"
    config_file = config_dir / "config"

    if not config_file.exists():
        config_dir.mkdir(parents=True, exist_ok=True)
        config_file.write_text(
            "# Night mode daemon configuration\n"
            "# Edit and save — changes are picked up on next sunrise/sunset.\n"
            "#\n"
            "# Temperature is in Kelvin:\n"
            "#   6500 = neutral daylight (no filter)\n"
            "#   5000 = slightly warm\n"
            "#   4500 = warm (default night)\n"
            "#   4000 = very warm\n"
            "#   3500 = amber\n"
            "#   3000 = deep amber\n"
            "#\n"
            "# transition_minutes = time either side of sunrise/sunset to\n"
            "#   ramp between day and night temperatures (total window is 2x this)\n"
            "\n"
            "[nightmode]\n"
            f"latitude = {DEFAULTS['latitude']}\n"
            f"longitude = {DEFAULTS['longitude']}\n"
            f"temp_day = {DEFAULTS['temp_day']}\n"
            f"temp_night = {DEFAULTS['temp_night']}\n"
            f"transition_minutes = {DEFAULTS['transition_minutes']}\n"
            f"interval = {DEFAULTS['interval']}\n"
        )

    cp = configparser.ConfigParser()
    cp.read_dict({"nightmode": DEFAULTS})
    cp.read(config_file)
    section = cp["nightmode"]

    return {
        "latitude": float(section["latitude"]),
        "longitude": float(section["longitude"]),
        "temp_day": int(section["temp_day"]),
        "temp_night": int(section["temp_night"]),
        "transition_minutes": int(section["transition_minutes"]),
        "interval": int(section["interval"]),
    }


# =====================================================================
#  NOAA sunrise/sunset calculation
# =====================================================================

def _sun_calc(dt: datetime, lat: float, lon: float) -> tuple[time, time]:
    """
    Calculate sunrise and sunset times for the given date at lat/lon.
    Returns (sunrise, sunset) as datetime.time objects in local time.
    Based on NOAA solar calculator spreadsheet.
    """
    rad = math.radians
    deg = math.degrees

    day = dt.toordinal() - (734124 - 40529)
    t = 0.5
    tz_offset = dt.utcoffset()
    tz_hours = tz_offset.total_seconds() / 3600 if tz_offset else 0

    jday = day + 2415018.5 + t - tz_hours / 24
    jcent = (jday - 2451545) / 36525

    manom = 357.52911 + jcent * (35999.05029 - 0.0001537 * jcent)
    mlong = (280.46646 + jcent * (36000.76983 + jcent * 0.0003032)) % 360
    eccent = 0.016708634 - jcent * (0.000042037 + 0.0001537 * jcent)
    mobliq = 23 + (26 + (21.448 - jcent * (46.815 + jcent * (0.00059 - jcent * 0.001813))) / 60) / 60
    obliq = mobliq + 0.00256 * math.cos(rad(125.04 - 1934.136 * jcent))
    vary = math.tan(rad(obliq / 2)) ** 2

    seqcent = (
        math.sin(rad(manom)) * (1.914602 - jcent * (0.004817 + 0.000014 * jcent))
        + math.sin(rad(2 * manom)) * (0.019993 - 0.000101 * jcent)
        + math.sin(rad(3 * manom)) * 0.000289
    )
    struelong = mlong + seqcent
    sapplong = struelong - 0.00569 - 0.00478 * math.sin(rad(125.04 - 1934.136 * jcent))
    declination = deg(math.asin(math.sin(rad(obliq)) * math.sin(rad(sapplong))))

    eqtime = 4 * deg(
        vary * math.sin(2 * rad(mlong))
        - 2 * eccent * math.sin(rad(manom))
        + 4 * eccent * vary * math.sin(rad(manom)) * math.cos(2 * rad(mlong))
        - 0.5 * vary * vary * math.sin(4 * rad(mlong))
        - 1.25 * eccent * eccent * math.sin(2 * rad(manom))
    )

    hourangle = deg(math.acos(
        math.cos(rad(90.833)) / (math.cos(rad(lat)) * math.cos(rad(declination)))
        - math.tan(rad(lat)) * math.tan(rad(declination))
    ))

    solarnoon = (720 - 4 * lon - eqtime + tz_hours * 60) / 1440
    sunrise_t = solarnoon - hourangle * 4 / 1440
    sunset_t = solarnoon + hourangle * 4 / 1440

    def decimal_to_time(d):
        hours = 24.0 * d
        h = int(hours)
        minutes = (hours - h) * 60
        m = int(minutes)
        seconds = (minutes - m) * 60
        s = int(seconds)
        return time(hour=max(0, min(23, h)), minute=max(0, min(59, m)), second=max(0, min(59, s)))

    return decimal_to_time(sunrise_t), decimal_to_time(sunset_t)


# =====================================================================
#  Temperature interpolation
# =====================================================================

def _time_to_minutes(t: time) -> float:
    """Convert a time object to minutes since midnight."""
    return t.hour * 60 + t.minute + t.second / 60


def calculate_temperature(now: datetime, cfg: dict) -> int:
    """
    Calculate the target colour temperature for the current time.
    Transitions linearly over transition_minutes either side of sunrise/sunset.
    """
    sunrise, sunset = _sun_calc(now, cfg["latitude"], cfg["longitude"])
    now_m = _time_to_minutes(now.time())
    sunrise_m = _time_to_minutes(sunrise)
    sunset_m = _time_to_minutes(sunset)
    half = cfg["transition_minutes"]
    temp_day = cfg["temp_day"]
    temp_night = cfg["temp_night"]

    sr_start = sunrise_m - half
    sr_end = sunrise_m + half
    ss_start = sunset_m - half
    ss_end = sunset_m + half

    if sr_start <= now_m <= sr_end:
        progress = (now_m - sr_start) / (sr_end - sr_start)
        return int(temp_night + (temp_day - temp_night) * progress)
    elif ss_start <= now_m <= ss_end:
        progress = (now_m - ss_start) / (ss_end - ss_start)
        return int(temp_day + (temp_night - temp_day) * progress)
    elif sr_end < now_m < ss_start:
        return temp_day
    else:
        return temp_night


# =====================================================================
#  Hyprsunset IPC
# =====================================================================

def apply_temperature(temp: int, temp_day: int) -> None:
    """Set hyprsunset temperature via hyprctl IPC."""
    global last_temp
    if temp == last_temp:
        return

    if temp >= temp_day:
        subprocess.run(["hyprctl", "hyprsunset", "identity"],
                       capture_output=True)
    else:
        subprocess.run(["hyprctl", "hyprsunset", "temperature", str(temp)],
                       capture_output=True)
    last_temp = temp


def notify(msg: str) -> None:
    """Send a desktop notification."""
    subprocess.run(["notify-send", "-a", "nightmode", "Night Mode", msg],
                   capture_output=True)


# =====================================================================
#  StatusNotifierItem (system tray icon)
# =====================================================================

async def run_tray(loop: asyncio.AbstractEventLoop):
    """Register a StatusNotifierItem on the session D-Bus."""
    from dbus_next.aio import MessageBus
    from dbus_next.service import ServiceInterface, method, dbus_property, signal as dbus_signal
    from dbus_next.constants import PropertyAccess
    from dbus_next import Variant, BusType

    SERVICE_NAME = "org.kde.StatusNotifierItem-nightmode-{pid}".format(pid=os.getpid())
    OBJECT_PATH = "/StatusNotifierItem"
    WATCHER_BUS = "org.kde.StatusNotifierWatcher"
    WATCHER_PATH = "/StatusNotifierWatcher"

    class StatusNotifierItem(ServiceInterface):
        def __init__(self):
            super().__init__("org.kde.StatusNotifierItem")
            self._icon = "weather-clear-night"
            self._status = "Active"
            self._tooltip_body = ""

        def update_state(self, active: bool, tooltip: str):
            self._icon = "weather-clear-night" if active else "weather-clear"
            self._status = "Active" if active else "Passive"
            self._tooltip_body = tooltip
            self.NewIcon()
            self.NewStatus(self._status)
            self.NewToolTip()

        # --- Properties ---

        @dbus_property(PropertyAccess.READ)
        def Category(self) -> 's':
            return "SystemServices"

        @dbus_property(PropertyAccess.READ)
        def Id(self) -> 's':
            return "nightmode"

        @dbus_property(PropertyAccess.READ)
        def Title(self) -> 's':
            return "Night Mode"

        @dbus_property(PropertyAccess.READ)
        def Status(self) -> 's':
            return self._status

        @dbus_property(PropertyAccess.READ)
        def IconName(self) -> 's':
            return self._icon

        @dbus_property(PropertyAccess.READ)
        def ToolTip(self) -> '(sa(iiay)ss)':
            return ["", [], "Night Mode", self._tooltip_body]

        @dbus_property(PropertyAccess.READ)
        def ItemIsMenu(self) -> 'b':
            return False

        @dbus_property(PropertyAccess.READ)
        def WindowId(self) -> 'i':
            return 0

        @dbus_property(PropertyAccess.READ)
        def IconThemePath(self) -> 's':
            return ""

        @dbus_property(PropertyAccess.READ)
        def Menu(self) -> 'o':
            return "/NO_DBUSMENU"

        @dbus_property(PropertyAccess.READ)
        def AttentionIconName(self) -> 's':
            return ""

        @dbus_property(PropertyAccess.READ)
        def OverlayIconName(self) -> 's':
            return ""

        @dbus_property(PropertyAccess.READ)
        def IconPixmap(self) -> 'a(iiay)':
            return []

        @dbus_property(PropertyAccess.READ)
        def AttentionIconPixmap(self) -> 'a(iiay)':
            return []

        @dbus_property(PropertyAccess.READ)
        def OverlayIconPixmap(self) -> 'a(iiay)':
            return []

        # --- Methods ---

        @method()
        def Activate(self, x: 'i', y: 'i'):
            """Called when the tray icon is clicked."""
            os.kill(os.getpid(), signal.SIGUSR1)

        @method()
        def SecondaryActivate(self, x: 'i', y: 'i'):
            pass

        @method()
        def Scroll(self, delta: 'i', orientation: 's'):
            pass

        @method()
        def ContextMenu(self, x: 'i', y: 'i'):
            pass

        # --- Signals ---

        @dbus_signal()
        def NewIcon(self):
            pass

        @dbus_signal()
        def NewStatus(self, status: 's'):
            pass

        @dbus_signal()
        def NewToolTip(self):
            pass

    # Stub menu interface so the tray host doesn't get errors probing /NO_DBUSMENU
    class DbusmenuStub(ServiceInterface):
        def __init__(self):
            super().__init__("com.canonical.dbusmenu")

    try:
        bus = await MessageBus(bus_type=BusType.SESSION).connect()

        item = StatusNotifierItem()
        bus.export(OBJECT_PATH, item)
        bus.export("/NO_DBUSMENU", DbusmenuStub())
        await bus.request_name(SERVICE_NAME)

        # Register with the StatusNotifierWatcher
        try:
            introspection = await bus.introspect(WATCHER_BUS, WATCHER_PATH)
            proxy = bus.get_proxy_object(WATCHER_BUS, WATCHER_PATH, introspection)
            watcher = proxy.get_interface("org.kde.StatusNotifierWatcher")
            await watcher.call_register_status_notifier_item(SERVICE_NAME)
        except Exception as e:
            print(f"nightmode: could not register with StatusNotifierWatcher: {e}")
            print("nightmode: tray icon may not appear (no watcher running?)")

        global tray
        tray = item

        # Update initial state
        now = datetime.now().astimezone()
        temp = calculate_temperature(now, config)
        active = not forced_off and temp < config["temp_day"]
        item.update_state(active, f"{temp}K" if not forced_off else "Disabled")

        print("nightmode: tray icon registered")
        await bus.wait_for_disconnect()

    except Exception as e:
        print(f"nightmode: tray error: {e}")


def update_tray():
    """Update tray icon state to reflect current mode."""
    if tray is None:
        return
    now = datetime.now().astimezone()
    temp = calculate_temperature(now, config)
    if forced_off:
        tray.update_state(False, "Disabled")
    else:
        active = temp < config["temp_day"]
        tray.update_state(active, f"{temp}K")


# =====================================================================
#  Toggle handler
# =====================================================================

def do_toggle():
    """Toggle forced-off state. Applies immediately."""
    global forced_off, last_temp
    forced_off = not forced_off
    if forced_off:
        subprocess.run(["hyprctl", "hyprsunset", "identity"], capture_output=True)
        last_temp = None
        notify("Disabled")
    else:
        last_temp = None
        now = datetime.now().astimezone()
        temp = calculate_temperature(now, config)
        apply_temperature(temp, config["temp_day"])
        notify(f"Enabled — {temp}K")
    update_tray()


# =====================================================================
#  Main loop
# =====================================================================

async def temperature_loop():
    """Main loop: update temperature every interval seconds."""
    global forced_off, config

    now = datetime.now().astimezone()
    sunrise, sunset = _sun_calc(now, config["latitude"], config["longitude"])
    temp = calculate_temperature(now, config)
    print(f"nightmode: {config['latitude']}°N, {config['longitude']}°W")
    print(f"nightmode: today sunrise={sunrise.strftime('%H:%M')} sunset={sunset.strftime('%H:%M')}")
    print(f"nightmode: range {config['temp_night']}K–{config['temp_day']}K, transition ±{config['transition_minutes']}m")
    print(f"nightmode: starting at {temp}K")

    apply_temperature(temp, config["temp_day"])
    update_tray()

    while True:
        await asyncio.sleep(config["interval"])

        if forced_off:
            now = datetime.now().astimezone()
            sunrise, _ = _sun_calc(now, config["latitude"], config["longitude"])
            now_m = _time_to_minutes(now.time())
            sr_m = _time_to_minutes(sunrise)
            if abs(now_m - sr_m) < 2:
                forced_off = False
                config = load_config()
                notify("Enabled — sunrise")
                update_tray()
            else:
                continue

        now = datetime.now().astimezone()
        temp = calculate_temperature(now, config)
        apply_temperature(temp, config["temp_day"])
        update_tray()


async def main_async():
    """Run temperature loop and tray icon concurrently."""
    await asyncio.gather(
        temperature_loop(),
        run_tray(asyncio.get_event_loop()),
    )


def main():
    global config
    config = load_config()

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    # Handle SIGUSR1 for toggle
    loop.add_signal_handler(signal.SIGUSR1, do_toggle)

    # Write PID file
    pid_file = os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
        "nightmode.pid"
    )
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    try:
        loop.run_until_complete(main_async())
    except KeyboardInterrupt:
        pass
    finally:
        try:
            os.unlink(pid_file)
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
