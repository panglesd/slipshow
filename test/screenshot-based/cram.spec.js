import { test, expect } from '@playwright/test';
import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { pathToFileURL } from 'url';

// Cram-like screenshot tests: every folder containing a run.json is a test
// folder. run.json is a list of entries of the form
//   { "entry": "foo.slp", "steps": [0, 1, 2] }
// A .slp entry is compiled with the slipshow in the PATH (run the tests with
// `dune exec --profile release -- npx playwright test` to use the one built by
// dune). A .html entry is used as is (it may be produced by a dune rule, so
// run `dune build --profile release` first). Each step is then screenshotted,
// in the screenshots/ subfolder of the test folder.

const ignoredDirs = new Set(['node_modules', 'test-results', 'playwright-report', 'blob-report']);

function findTestDirs(dir) {
    const shouldVisit = e =>
        e.isDirectory() && !ignoredDirs.has(e.name) && !e.name.startsWith('.');
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    const subdirs = entries
        .filter(shouldVisit)
        .flatMap(e => findTestDirs(path.join(dir, e.name)));
    return entries.some(e => e.isFile() && e.name === 'run.json') ? [dir, ...subdirs] : subdirs;
}

for (const dir of findTestDirs(__dirname)) {
    const relDir = path.relative(__dirname, dir);
    const runFile = path.join(dir, 'run.json');
    const config = JSON.parse(fs.readFileSync(runFile, 'utf8'));
    if (!Array.isArray(config))
        throw new Error(`${runFile}: expected a list of { entry, steps } objects`);

    for (const { entry, steps = [0] } of config) {
        if (typeof entry !== 'string')
            throw new Error(`${runFile}: missing "entry" field`);
        const name = path.parse(entry).name;
        const isHtml = path.extname(entry) === '.html';

        test.describe(`${relDir}/${entry}`, () => {
            let presUrl;

            test.beforeAll(async ({}, testInfo) => {
                if (isHtml) {
                    const file = path.join(dir, entry);
                    if (!fs.existsSync(file))
                        throw new Error(`${file} does not exist, did you run \`dune build\`?`);
                    presUrl = pathToFileURL(file).href;
                    return;
                }
                // Several workers (and projects) may compile the same entry
                // concurrently, so each gets its own output file.
                const output = path.join(
                    testInfo.project.outputDir, 'compiled', testInfo.project.name,
                    `worker-${testInfo.workerIndex}`, relDir, `${name}.html`);
                fs.mkdirSync(path.dirname(output), { recursive: true });
                execFileSync('slipshow', ['compile', path.join(dir, entry), '-o', output],
                    { stdio: ['ignore', 'inherit', 'inherit'] });
                presUrl = pathToFileURL(output).href;
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
}
