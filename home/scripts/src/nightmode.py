#!/usr/bin/env python3
"""
Automatic night mode daemon for hyprsunset.

Calculates sunrise/sunset for Warrington (53.39°N, 2.60°W) using the
NOAA solar position algorithm, then smoothly interpolates screen colour
temperature between day and night across a configurable transition
window around each event.

Runs as a background loop, updating hyprsunset via IPC every 30 seconds.

Toggle: send SIGUSR1 to force night mode on/off. When forced off, the
daemon stops updating until toggled again (or until the next sunrise,
which auto-re-enables).

Config: ~/.config/nightmode/config (optional, created on first run).
"""

import configparser
import math
import os
import signal
import subprocess
import sys
import time as time_mod
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

    Transitions linearly over transition_minutes either side of
    sunrise and sunset.
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
#  Signal handler for toggle
# =====================================================================

def handle_toggle(signum, frame):
    """SIGUSR1 toggles forced-off state. Applies immediately."""
    global forced_off, last_temp
    forced_off = not forced_off
    if forced_off:
        subprocess.run(["hyprctl", "hyprsunset", "identity"], capture_output=True)
        last_temp = None
        notify("Disabled")
    else:
        # Re-apply immediately — don't wait for next tick
        last_temp = None
        now = datetime.now().astimezone()
        temp = calculate_temperature(now, config)
        apply_temperature(temp, config["temp_day"])
        notify(f"Enabled — {temp}K")


# =====================================================================
#  Main loop
# =====================================================================

def get_local_now() -> datetime:
    """Get current local time with timezone info."""
    return datetime.now().astimezone()


def main():
    global forced_off, config

    config = load_config()

    signal.signal(signal.SIGUSR1, handle_toggle)

    # Write PID file so the toggle script can find us
    pid_file = os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
        "nightmode.pid"
    )
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    # Log startup
    now = get_local_now()
    sunrise, sunset = _sun_calc(now, config["latitude"], config["longitude"])
    temp = calculate_temperature(now, config)
    print(f"nightmode: {config['latitude']}°N, {config['longitude']}°W")
    print(f"nightmode: today sunrise={sunrise.strftime('%H:%M')} sunset={sunset.strftime('%H:%M')}")
    print(f"nightmode: range {config['temp_night']}K–{config['temp_day']}K, transition ±{config['transition_minutes']}m")
    print(f"nightmode: starting at {temp}K")

    apply_temperature(temp, config["temp_day"])

    while True:
        time_mod.sleep(config["interval"])

        if forced_off:
            now = get_local_now()
            sunrise, _ = _sun_calc(now, config["latitude"], config["longitude"])
            now_m = _time_to_minutes(now.time())
            sr_m = _time_to_minutes(sunrise)
            if abs(now_m - sr_m) < 2:
                forced_off = False
                config = load_config()  # reload config at sunrise
                notify("Enabled — sunrise")
            else:
                continue

        now = get_local_now()
        temp = calculate_temperature(now, config)
        apply_temperature(temp, config["temp_day"])


if __name__ == "__main__":
    main()
