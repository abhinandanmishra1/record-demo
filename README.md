<img src=".github/video.svg" width="130" alt="">

# /record-demo

Skill to make your agent record a demo of your web app, with voice-over,
entirely on your machine — forked from
[nilbuild/video-demo](https://github.com/nilbuild/video-demo) for company
use, with two changes that matter for filming an internal, signed-in tool:

- **CDP-attach**: films through an already-open, already-logged-in
  Chrome/Edge debug browser instead of a fresh headless one, so a real
  session is never simulated by extracting a cookie or a password. Set
  `DEMO_CDP_URL` (e.g. `http://localhost:9222`) to use it; unset, it behaves
  exactly like the upstream skill and launches its own browser.
- **Mutation guard**: every `POST`/`PUT`/`PATCH`/`DELETE` to the app's own
  origin is blocked by default while filming `site` mode, and only goes
  through if explicitly allow-listed in `demo.config.ts`'s
  `allowMutations`. A scripted click landing on the wrong button cannot
  submit a form or delete a row.

Private fork, company use only — not published under this feature set.

## Setup

```bash
scripts/setup.sh
```

One command: checks dependencies, installs the engine and ffmpeg (against
the public npm registry by default, working around a company registry
proxy that 403s on public packages), offers the voice model, and checks for
a reachable CDP debug browser — printing the exact command to start one if
none is running.

## Record a demo

```bash
/record-demo [explain what to record]

/record-demo record a demo of https://example.com
/record-demo record the checkout flow on https://example.com, use cash on delivery
/record-demo visit http://roadmap.sh and record the roadmap search flow
/record-demo record the login flow in the current project
```

Be as broad or as specific as you like. You can also add video instructions
too e.g. "tell them it works offline now", "mention the keyboard shortcut",
"keep it under twenty seconds".

To film a real signed-in internal tool: open it in a Chrome/Edge instance
started with `--remote-debugging-port=9222 --remote-allow-origins=*` (both
required — Playwright can't attach without the second one) and sign in
normally, then set `DEMO_CDP_URL=http://localhost:9222` before filming.
The recording happens in that literal browser window — watch it happen.

## Ask for updates

If you are not happy with the produced recording, you can ask for updates
to the recorded video e.g.

- "that line is too long", "say screenshots, not stills"
- "zoom in more on the toolbar", "stop zooming so much"
- "slow down at the end", "say thanks for watching at the end"
- "record the calendar first", "record the pricing page too"
- "try a different voice", "no voice-over on this one"

Say what is wrong and it can keep re-recording until you are happy.

## What you get

An mp4 video is produced with the voice-over on it. It also keeps
screenshots at every moment worth keeping. Everything is done on your
local machine — nothing is uploaded, ever.

## Licence

MIT © [Kamran Ahmed](https://kamran.fyi), original work. Modifications for
CDP-attach and the mutation guard are unpublished, company-internal changes.
