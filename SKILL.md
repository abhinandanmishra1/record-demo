---
name: record-demo
description: Films a web app as narrated, zooming, cursor-driven demo videos with retina screenshots, either from a repo it builds and mocks or from a live URL as it is served. Use when the user asks for a demo video, product video, walkthrough, screencast, screen recording of an app or of a URL, hero or landing-page footage, app screenshots for a website, "show off this feature", "record a demo of <url>", or wants to add, re-film, re-narrate or fix a demo scene.
---

# record-demo

`scripts/demo` films a web app and writes `demo-out/` into that project's
workspace: per scene an mp4 with voice-over, a poster, retina stills, plus
`full-tour.mp4`, `manifest.json` and `index.html`. All local. The engine runs
from this skill; nothing is installed into the app being filmed.

## Non-negotiables

Each of these cost a run or a user's patience.

1. **A pinned build, never a dev server.** Its module graph belongs to whoever
   is editing source. Copy it somewhere private and verify its API base by
   reading the bundle. A URL with no repo behind it is `site` mode; a URL on
   localhost is a dev server and is never filmed.
2. **In `build` mode, mock every request in-process and pin the clock.** A
   corpus gets published, and a real account publishes real people's
   addresses. `site` mode trades both away knowingly — but for a real
   signed-in internal tool, `DEMO_CDP_URL` plus `allowMutations` below is
   what makes that trade safe rather than reckless.
3. **Own your port and output directory.** The studio refuses to adopt a server
   it did not start. Never `pkill` by pattern.
4. **1080p60 video, 2x stills, by default only.** They are separate
   settings — `stage`/`DEMO_VIDEO_SCALE` raise the video, `DEMO_STILL_SCALE`
   the stills — and both can go higher than default. What does not move is
   the trade: throughput is a fixed pixels-per-second budget, so a higher
   resolution costs frame rate. The engine already prints "under 45fps of
   real paints... will read as judder" when a clip can't sustain it — that
   line is the signal to raise resolution against, not a guess.
5. **Filming a real signed-in tool needs `DEMO_CDP_URL`, never a cookie.**
   Point it at an already-open, already-logged-in Chrome/Edge debug browser
   (`http://localhost:9222`) and the recording happens in that literal
   window — the presenter watches every action, and no credential material
   is ever read or written by a scene. Never extract a session cookie, a
   token, or a password to fake a signed-in browser instead.
6. **`site` mode's mutations are denied by default.** `allowMutations` in
   `demo.config.ts` is the only way a `POST`/`PUT`/`PATCH`/`DELETE` to the
   app's own origin gets through while filming; anything not listed there
   is aborted before it leaves the browser, loudly, with the blocked
   method and URL printed. A scene that needs a real mutation names it
   there first — it is never assumed safe by omission.
7. **Do the gesture, then narrate while pushed in on the result.** One subject
   per line. Never narrate before the subject exists. Where the app has its own
   timer — an undo window, a toast — the gesture goes inside it and the words
   after, or the film shows a feature that does not work.
8. **One scene, then stop and ask** (step 8). It caught four defects before
   twenty-six more scenes were filmed.
9. **Read the PNG, every time.** A scene that passes while framing the wrong
   thing is a failure, and only an eye on the still catches it.
10. **Nothing is final until they say so.** Any note about the words, the
   framing, the pace, what is covered or the voice is a re-film, not a
   negotiation: change it and film it again. They cannot see what you can, so
   "too long", "zoom in more" and "stop zooming so much" are all complete
   instructions, and a scene is cheap to shoot twice.

## Workflow

1. **Pick the mode from what you were given. Do not ask.** An http(s) URL on
   a public host is `site`, workspace `~/.record-demo/<host>/`. A URL on
   localhost or a private address is a dev server: find the repo behind it and
   treat the request as that repo. No URL means the repo you are in, so walk
   up and look for a web app (a `package.json` with a build script beside a
   Vite, React Router, Next, Astro, SvelteKit or Remix config). Exactly one is
   `build`; several, ask which; none, ask for a URL or a path. A workspace
   whose `.origin` already names this repo is reused, not scaffolded again.
   Say the mode and the workspace path in one line and carry on.
2. `scripts/setup.sh`, then **set yourself up before asking anything else of
   the user.** They installed a skill; they did not sign up to run four
   scripts by hand. One command: dependencies, engine, ffmpeg (against the
   public npm registry by default — a company registry proxy 403ing on
   public packages is common and this works around it without being asked),
   the voice model once they agree to the ~350MB, and a check for a
   reachable `DEMO_CDP_URL` debug browser, printing the exact command to
   start one if none is running. Never install anything without asking, and
   never hand them a doctor report to interpret. Two things it will not do,
   and nor should you: upgrade their Node, because which tool owns it is
   theirs to know, and run `sudo`, because a password prompt in a script
   nobody is watching just hangs. In both cases the script prints the one
   command and you pass it on.
3. **Discover, writing nothing.** `site`: open the URL and read it, for what
   the page is for, the three things worth showing, and what is stable enough
   to point at. If it lands on a sign-in, that is `DEMO_CDP_URL`'s case, not a
   reason to stop: ask whether a debug browser is already signed in, point
   `DEMO_CDP_URL` at it, and set `allowMutations` to whatever the scenes
   genuinely need to submit — never assume, never extract a cookie instead.
   With no debug browser on offer, ask for that or for a public URL. `build`: the build command
   copied verbatim out of `package.json`; the output directory from the
   framework's config; any absolute API host in `.env*` (it goes in
   `build.forbid`); the key the theme boot script reads; an existing fixture
   API or MSW handlers; `data-testid` density; routes with no credential.
4. `scripts/scaffold.mjs <appRoot>`, or `scripts/scaffold.mjs --site <url>`.
   Neither writes anything into the app.
5. **Fill in the workspace's `demo.config.ts`.** A required field still
   unknown means discovery is not done. [config.md](references/config.md)
6. **`build` only: write `mock.ts` and `seed/`.** Reuse the repo's own data
   fixtures where it has them, but never a file that imports
   `@playwright/test`: two copies in one run is an error Playwright refuses,
   and it fails the whole corpus rather than the one scene that did it. Then
   `DEMO_VOICE=0 scripts/demo --grep smoke`. Reuse the repo's fixture API if it has one
   ([mocking.md](references/mocking.md)). Read the still: signed in, seeded
   data, right theme, no login page. Read the capture line. Fix until both are
   right, then write `demo/ui.ts` with only what the smoke run proved.
7. **Film what they asked for, at the scope they asked for it.** A named
   feature is one scene: write it, film it, hand it over. Do not answer "record
   the search on the home page" with a ten-scene proposal, and do not quietly
   widen the ask because the product has more in it. Only when the request is
   the whole product do you **propose 6 to 10 scenes**, each a title and a
   one-line blurb in tour order, and ask which to film first.
8. **STOP.** Film that one scene with voice. Verify the spoken count matches the
   `say` calls, nothing overran, the rate held. Read every still. Give the user
   the mp4 path and ask about the writing's register, the zoom scale, the pacing
   and the voice. **Write nothing else until they answer.**
9. Then batches of three or four via `--grep`; the manifest merges. Read the
   stills after every batch. `DEMO_BUILD=0 scripts/demo` skips the rebuild while iterating
   on a scene — twenty seconds instead of four minutes; drop it for the run
   that produces the corpus.
10. Full run with `DEMO_TRACE_FRAMES=1`, then `scripts/gaps.mjs` and open
   `demo-out/index.html`. Report the capture table and any slow clips.

## A scene

```ts
scene('tasks', { title: 'Your to-dos, beside your calendar', blurb: '...' },
  async ({ actor, page, shot }) => {
    await actor.click(page.getByRole('radio', { name: 'Today' }));
    await actor.settle();
    await actor.spotlight(
      row('Send Sam the feedback'),
      'And this one is from yesterday that I never got to, so it is flagged.',
      { scale: 1.8, stay: true }
    );
    await shot('overdue');
    await actor.unfocus();
  });
```

`spotlight` takes the narration mark, then moves camera and cursor over the
line's opening words. Scale by subject: panel ~1.4, row ~1.7, single control ~2.
A line about the whole screen gets a plain `say` and no zoom. `unfocus` is a
hint rather than a movement: the camera only comes out when something needs
it wide, so consecutive beats about the same region glide instead of bouncing.
[scenes.md](references/scenes.md) · [narration.md](references/narration.md)

## Never

Subtitles (the voice is the channel). Cloud TTS (the film is of private data).
Playwright's `recordVideo` (no control of rate, size or start; the recorder
replaces it). 4K as a default. Music, intro cards or cross-fades. Scenes
generated from a route crawl: a scene is choreography with a point. Retries: a
retried scene is a different film.

## Also

[capture.md](references/capture.md) before changing any capture number.
[runs.md](references/runs.md) for builds, isolation and the manifest.
[troubleshooting.md](references/troubleshooting.md) when a run dies or a shot
looks wrong. The engine runs from this skill, so a fix to `engine/` reaches
every project on the machine at once: edit it there, and nothing needs
propagating.
