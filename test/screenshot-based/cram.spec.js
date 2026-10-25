import { test, expect } from '@playwright/test';
import fs from 'fs';
import { pathToFileURL } from 'url';
import { findTests } from './tests.js';

// See tests.js for the format of the tests. The HTML files must have been
// generated first, with `dune build`.

for (const { relDir, entry, name, html, steps } of findTests()) {
    test.describe(`${relDir}/${entry}`, () => {
        const presUrl = pathToFileURL(html).href;

        test.beforeAll(() => {
            if (!fs.existsSync(html))
                throw new Error(`${html} does not exist, did you run \`dune build\`?`);
        });

        for (const step of steps) {
            test(`step ${step}`, async ({ page }) => {
                // The presentation runs in an iframe, which posts a
                // "Ready" message to its parent once it is initialized and
                // has reached the step given in the URL.
                await page.addInitScript(() => {
                    if (window !== window.top) return;
                    window.addEventListener('message', e => {
                        if (typeof e.data === 'string' && e.data.includes('(payload Ready)'))
                            window.slipshowReady = true;
                    });
                });
                await page.goto(`${presUrl}#${step}`);
                await page.waitForFunction(() => window.slipshowReady, null, { timeout: 60_000 });
                await page.mouse.move(-1, -1);
                await expect.soft(page).toHaveScreenshot(
                    [relDir, 'screenshots', `${name}-step-${String(step).padStart(2, '0')}.png`],
                    { timeout: 15_000 });
            });
        }
    });
}
