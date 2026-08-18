#!/bin/bash
# Wrapper that runs a benchmark under /usr/bin/time, captures peak RSS, and
# forwards the program's exit code to hyperfine.
#
# Usage (invoked by run_single.sh, not directly):
#   wrap_rss.sh <rss_log_file> <command> [args...]
#
# Each invocation appends one line to <rss_log_file>: `<rss_bytes>\n`.
# Failed runs (non-zero exit) are NOT logged, keeping the data clean.
#
# Why: hyperfine's own memory reading is unreliable, so we read ru_maxrss from
# /usr/bin/time and store it as the authoritative peak RSS. The two platforms
# differ and are normalized to BYTES here so downstream code is platform-agnostic:
#   - macOS (BSD time):  `-l`  prints "<bytes>  maximum resident set size" (bytes)
#   - Linux (GNU time):  `-v`  prints "Maximum resident set size (kbytes): <kb>"
# On Linux the kbytes value is multiplied by 1024 so the log is always bytes.

LOG="$1"
shift

# If /usr/bin/time is unavailable, still run the command (so hyperfine gets its
# wall-clock timing) but skip RSS capture rather than failing the whole sweep.
if [ ! -x /usr/bin/time ]; then
    EXIT=0
    "$@" >/dev/null 2>&1 || EXIT=$?
    exit "$EXIT"
fi

case "$(uname -s)" in
    Darwin) TIME_FLAG="-l" ;;   # BSD time, bytes
    *)      TIME_FLAG="-v" ;;   # GNU time, kbytes
esac

TMP_ERR=$(mktemp)
EXIT=0
# stdout → /dev/null (benchmark output is irrelevant for measurement and would
# flood hyperfine). stderr captures BOTH program stderr and time's report;
# awk grabs only the RSS line.
/usr/bin/time "$TIME_FLAG" "$@" >/dev/null 2>"$TMP_ERR" || EXIT=$?

if [ "$EXIT" -eq 0 ]; then
    if [ "$TIME_FLAG" = "-l" ]; then
        RSS=$(awk '/maximum resident set size/{print $1; exit}' "$TMP_ERR")
    else
        RSS_KB=$(awk -F': ' '/Maximum resident set size/{print $2; exit}' "$TMP_ERR")
        [ -n "$RSS_KB" ] && RSS=$((RSS_KB * 1024))
    fi
    [ -n "${RSS:-}" ] && echo "$RSS" >> "$LOG"
fi

rm -f "$TMP_ERR"
exit "$EXIT"
