#!/usr/bin/env python3
"""
Automatic night mode daemon for hyprsunset.

Calculates sunrise/sunset for Warrington (53.39°N, 2.60°W) using the
NOAA solar position algorithm, then smoothly interpolates screen colour
temperature between day (6500K, identity) and night (3500K) across a
90-minute transition window around each event.

Runs as a background loop, updating hyprsunset via IPC every 60 seconds.

Toggle: send SIGUSR1 to force night mode on/off. When forced off, the
daemon stops updating until toggled again (or until the next sunrise,
which auto-re-enables).
"""

import math
import os
import signal
import subprocess
import sys
import time as time_mod
from datetime import datetime, time, timedelta, timezone

# --- Location: Warrington, UK ---
LATITUDE = 53.39
LONGITUDE = -2.60

# --- Temperature range ---
TEMP_DAY = 6500    # neutral daylight
TEMP_NIGHT = 3500  # warm night

# --- Transition duration (minutes each side of sunrise/sunset) ---
TRANSITION_MINUTES = 45

# --- Update interval (seconds) ---
INTERVAL = 60

# --- State ---
forced_off = False
last_temp = None


# =====================================================================
#  NOAA sunrise/sunset calculation
# =====================================================================

def _sun_calc(dt: datetime) -> tuple[time, time]:
    """
    Calculate sunrise and sunset times for the given date at LATITUDE/LONGITUDE.
    Returns (sunrise, sunset) as datetime.time objects in local time.
    Based on NOAA solar calculator spreadsheet.
    """
    rad = math.radians
    deg = math.degrees

    # Day number since 1900-01-01 (Excel epoch compat)
    day = dt.toordinal() - (734124 - 40529)
    t = 0.5  # calculate for noon
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
        math.cos(rad(90.833)) / (math.cos(rad(LATITUDE)) * math.cos(rad(declination)))
        - math.tan(rad(LATITUDE)) * math.tan(rad(declination))
    ))

    solarnoon = (720 - 4 * LONGITUDE - eqtime + tz_hours * 60) / 1440
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


def calculate_temperature(now: datetime) -> int:
    """
    Calculate the target colour temperature for the current time.

    Transitions linearly over TRANSITION_MINUTES either side of
    sunrise and sunset:

        sunrise - 45m → sunrise + 45m : NIGHT → DAY
        sunset  - 45m → sunset  + 45m : DAY   → NIGHT
        between sunrise+45m and sunset-45m : DAY (identity)
        between sunset+45m and sunrise-45m : NIGHT
    """
    sunrise, sunset = _sun_calc(now)
    now_m = _time_to_minutes(now.time())
    sunrise_m = _time_to_minutes(sunrise)
    sunset_m = _time_to_minutes(sunset)
    half = TRANSITION_MINUTES

    # Sunrise transition window
    sr_start = sunrise_m - half
    sr_end = sunrise_m + half

    # Sunset transition window
    ss_start = sunset_m - half
    ss_end = sunset_m + half

    if sr_start <= now_m <= sr_end:
        # Transitioning from night to day
        progress = (now_m - sr_start) / (sr_end - sr_start)
        return int(TEMP_NIGHT + (TEMP_DAY - TEMP_NIGHT) * progress)
    elif ss_start <= now_m <= ss_end:
        # Transitioning from day to night
        progress = (now_m - ss_start) / (ss_end - ss_start)
        return int(TEMP_DAY + (TEMP_NIGHT - TEMP_DAY) * progress)
    elif sr_end < now_m < ss_start:
        # Full daylight
        return TEMP_DAY
    else:
        # Full night
        return TEMP_NIGHT


# =====================================================================
#  Hyprsunset IPC
# =====================================================================

def apply_temperature(temp: int) -> None:
    """Set hyprsunset temperature via hyprctl IPC."""
    global last_temp
    if temp == last_temp:
        return

    if temp >= TEMP_DAY:
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
    """SIGUSR1 toggles forced-off state."""
    global forced_off, last_temp
    forced_off = not forced_off
    if forced_off:
        subprocess.run(["hyprctl", "hyprsunset", "identity"], capture_output=True)
        last_temp = None
        notify("Disabled")
    else:
        last_temp = None  # force re-apply on next tick
        notify("Enabled — following schedule")


# =====================================================================
#  Main loop
# =====================================================================

def get_local_now() -> datetime:
    """Get current local time with timezone info."""
    return datetime.now().astimezone()


def main():
    global forced_off

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
    sunrise, sunset = _sun_calc(now)
    temp = calculate_temperature(now)
    print(f"nightmode: Warrington ({LATITUDE}°N, {LONGITUDE}°W)")
    print(f"nightmode: today sunrise={sunrise.strftime('%H:%M')} sunset={sunset.strftime('%H:%M')}")
    print(f"nightmode: starting at {temp}K")

    # Initial apply
    apply_temperature(temp)

    while True:
        time_mod.sleep(INTERVAL)

        if forced_off:
            # Auto-re-enable at sunrise (new day, fresh start)
            now = get_local_now()
            sunrise, _ = _sun_calc(now)
            now_m = _time_to_minutes(now.time())
            sr_m = _time_to_minutes(sunrise)
            # Re-enable within 2 minutes of sunrise
            if abs(now_m - sr_m) < 2:
                forced_off = False
                notify("Enabled — sunrise")
            else:
                continue

        now = get_local_now()
        temp = calculate_temperature(now)
        apply_temperature(temp)


if __name__ == "__main__":
    main()
