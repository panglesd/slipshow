import { test, expect } from '@playwright/test';
import fs from 'fs';
import { pathToFileURL } from 'url';
import { findTests } from './tests.js';

// See tests.js for the format of the tests. The HTML files must have been
// generated first, with `dune build`.

for (const { relDir, entry, name, html, steps } of findTests()) {
    test.describe(`${relDir}/${entry}`, () => {
        // The presentation is loaded once, and each test moves it to its step.
        // If a test fails, the next one runs in a new worker, which loads the
        // presentation again.
        let page;

        test.beforeAll(async ({ browser }) => {
            if (!fs.existsSync(html))
                throw new Error(`${html} does not exist, did you run \`dune build\`?`);
            page = await browser.newPage();
            // The presentation runs in an iframe, which posts a "Ready"
            // message to its parent once it is initialized.
            await page.addInitScript(() => {
                if (window !== window.top) return;
                window.addEventListener('message', e => {
                    if (typeof e.data === 'string' && e.data.includes('(payload Ready)'))
                        window.slipshowReady = true;
                });
            });
            await page.goto(pathToFileURL(html).href);
            await page.waitForFunction(() => window.slipshowReady, null, { timeout: 60_000 });
        });

        test.afterAll(async () => {
            await page?.close();
        });

        for (const step of steps) {
            test(`step ${step}`, async () => {
                // Same message as the one sent by the parent to the iframe
                // to set its initial state
                await page.evaluate(step => {
                    document.getElementById('slipshow__internal_iframe').contentWindow
                        .postMessage(`((payload(State ${step} Fast))(id test))`, '*');
                }, step);
                // The counter shows "from→to" during a transition, and the
                // step once it is reached.
                await expect(page.frameLocator('#slipshow__internal_iframe').locator('#slipshow-counter'))
                    .toHaveText(String(step), { timeout: 30_000 });
                await page.mouse.move(-1, -1);
                await expect.soft(page).toHaveScreenshot(
                    [relDir, 'screenshots', `${name}-step-${String(step).padStart(2, '0')}.png`],
                    { timeout: 15_000 });
            });
        }
    });
}
