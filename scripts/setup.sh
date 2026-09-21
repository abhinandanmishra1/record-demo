#!/usr/bin/env bash
set -uo pipefail

# One command instead of four. `doctor.sh`, `install.sh` and
# `install-voice.sh` still exist and still work standalone — this wraps them
# so nobody has to know to run all three, or to know that a company npm
# registry proxy that 403s on public packages (a real one hit while building
# this) needs `npm_config_registry` overridden before `install.sh`'s `npm`
# calls will succeed. That override is scoped to this script's own process,
# not written into any global npm config.

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export npm_config_registry="${npm_config_registry:-https://registry.npmjs.org}"

printf 'setup: checking what is already here\n\n'
"$SKILL/scripts/doctor.sh"
DOCTOR_STATUS=$?

if [ "$DOCTOR_STATUS" -ne 0 ]; then
  printf '\nsetup: installing the engine, ffmpeg and chromium (about 250MB)\n\n'
  "$SKILL/scripts/install.sh"
fi

VOICE_HOME="${DEMO_VOICE_HOME:-$HOME/.cache/demo-voice}"
if [ ! -f "$VOICE_HOME/kokoro.onnx" ]; then
  printf '\nsetup: the local voice model is not installed (~350MB, once for this machine).\n'
  printf 'setup: filming silent is a fine answer if you would rather skip this.\n'
  read -r -p 'setup: install it now? [y/N] ' REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    "$SKILL/scripts/install-voice.sh"
  else
    printf 'setup: skipping — DEMO_VOICE=0 films silent, or run scripts/install-voice.sh later.\n'
  fi
fi

# CDP-attach is the safe way to film anything signed in — see SKILL.md's
# non-negotiables. Checked here, not enforced: a `build`-mode project has no
# use for it, and a `site` run against a genuinely public page doesn't either.
CDP_URL="${DEMO_CDP_URL:-http://localhost:9222}"
printf '\nsetup: checking for a CDP debug browser at %s\n' "$CDP_URL"
if curl -fsS --max-time 2 "$CDP_URL/json/version" >/dev/null 2>&1; then
  printf '  ok    debug browser reachable — set DEMO_CDP_URL=%s to film through it\n' "$CDP_URL"
else
  printf '  warn  no debug browser reachable at %s\n' "$CDP_URL"
  printf '        fix: open one before filming anything signed in, e.g.\n'
  printf '          open -a "Google Chrome" --args --remote-debugging-port=9222 "--remote-allow-origins=*" --user-data-dir="$HOME/.chrome-debug-profile"\n'
  printf '        (--remote-allow-origins is required — Playwright cannot attach without it)\n'
  printf '        then sign in normally in that window and set DEMO_CDP_URL=%s\n' "$CDP_URL"
fi

printf '\nsetup: done. scripts/doctor.sh any time to re-check.\n'
