import { chromium, test as base } from '@playwright/test';

import { CDP_URL, SITE } from './config.ts';

/**
 * The one seam CDP-attach lives behind.
 *
 * `DEMO_CDP_URL` unset: `test` is `base`, unchanged — Playwright launches
 * and tears down its own browser exactly as it always has, and nothing in
 * `scene.ts` or `stage.ts` can tell the difference.
 *
 * `DEMO_CDP_URL` set: `browser`/`context`/`page` are overridden to attach to
 * that browser over CDP and reuse its first context and a matching tab,
 * rather than opening a fresh one. `browser` is scoped to the *worker*, not
 * the test — confirmed by testing that a real Chrome only grants the
 * `Browser.setDownloadBehavior` call `connectOverCDP` makes internally to
 * the *first* client that ever asks for it in that process's lifetime;
 * every later `connectOverCDP` against the same running browser fails with
 * "Browser context management is not supported", even from a brand new
 * client. One connection per run, reused by every scene in it, is what
 * keeps a multi-scene run from hitting that on its second scene — it does
 * not fix a *second separate* `scripts/demo` invocation against the same
 * still-running browser, which is a real limit of the browser, not this
 * fixture; restart the debug browser between separate recording sessions.
 * Nothing attached is closed afterward: it is the presenter's own browser,
 * not this run's to tear down.
 */
export const test = CDP_URL
  ? base.extend<{}, { cdpBrowser: import('@playwright/test').Browser }>({
      cdpBrowser: [
        async ({}, use) => {
          const browser = await chromium.connectOverCDP(CDP_URL);
          await use(browser);
        },
        { scope: 'worker' },
      ],
      context: async ({ cdpBrowser }, use) => {
        const context =
          cdpBrowser.contexts()[0] ?? (await cdpBrowser.newContext());
        await use(context);
      },
      page: async ({ context }, use) => {
        const existing = SITE
          ? context.pages().find((page) => page.url().startsWith(SITE))
          : context.pages()[0];
        const page = existing ?? context.pages()[0] ?? (await context.newPage());
        await use(page);
      },
    })
  : base;
