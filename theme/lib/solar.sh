# Sunrise/sunset-based mode selection. Bash 3.2 compatible; needs awk.

# solar_times <lat> <lon> <day-of-year> <tz-offset-minutes>
# Prints "<sunrise> <sunset>" as local minutes after midnight (NOAA approximation).
# Fails (polar day/night, bad input) so callers can fall back to fixed hours.
solar_times() {
  awk -v lat="$1" -v lon="$2" -v doy="$3" -v tz="$4" 'BEGIN {
    pi = 3.14159265358979; rad = pi / 180
    if (lat == "" || lon == "" || lat < -90 || lat > 90 || lon < -180 || lon > 180) exit 1
    g = 2 * pi / 365 * (doy - 1)
    eq = 229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g) \
         - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
    d = 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2 * g) \
        + 0.000907 * sin(2 * g) - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)
    c = cos(90.833 * rad) / (cos(lat * rad) * cos(d)) - sin(lat * rad) * sin(d) / (cos(lat * rad) * cos(d))
    if (c < -1 || c > 1) exit 1
    ha = atan2(sqrt(1 - c * c), c) / rad
    rise = 720 - 4 * (lon + ha) - eq + tz
    set  = 720 - 4 * (lon - ha) - eq + tz
    rise = rise - 1440 * int(rise / 1440); if (rise < 0) rise += 1440
    set  = set  - 1440 * int(set  / 1440); if (set  < 0) set  += 1440
    printf "%d %d\n", rise, set
  }'
}

# solar_mode <now-minutes> <sunrise> <sunset>: dawn between sunrise and sunset.
solar_mode() {
  if [ "$2" -le "$3" ]; then
    if [ "$1" -ge "$2" ] && [ "$1" -lt "$3" ]; then echo dawn; else echo main; fi
  else # sunset wrapped past midnight in local time
    if [ "$1" -ge "$2" ] || [ "$1" -lt "$3" ]; then echo dawn; else echo main; fi
  fi
}

# auto_mode: solar if a location file ("lat lon") exists and works, else fixed hours.
# Test overrides: ROSEPINE_NOW_MIN, ROSEPINE_DOY, ROSEPINE_TZ_MIN.
auto_mode() {
  local loc="${ROSEPINE_LOCATION_FILE:-$HOME/.config/rose-pine/location}"
  local now doy tz z lat lon times
  now="${ROSEPINE_NOW_MIN:-$((10#$(date +%H) * 60 + 10#$(date +%M)))}"
  if [ -f "$loc" ]; then
    read -r lat lon < "$loc" || true
    doy="${ROSEPINE_DOY:-$((10#$(date +%j)))}"
    if [ -n "${ROSEPINE_TZ_MIN:-}" ]; then
      tz="$ROSEPINE_TZ_MIN"
    else
      z="$(date +%z)"
      tz=$(( 10#${z:1:2} * 60 + 10#${z:3:2} ))
      [ "${z:0:1}" = "-" ] && tz=$((-tz))
    fi
    if times="$(solar_times "$lat" "$lon" "$doy" "$tz" 2>/dev/null)" && [ -n "$times" ]; then
      solar_mode "$now" ${times}
      return
    fi
  fi
  mode_for_hour $((now / 60))
}
