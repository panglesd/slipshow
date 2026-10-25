// Cram-like screenshot tests: every folder containing a run.json is a test
// folder. run.json is a list of entries of the form
//   { "entry": "foo.slp", "steps": [0, 1, 2] }
// A .html entry is used as is. Any other entry must be compiled to an HTML
// file next to run.json, with the same base name, by a rule of the dune file
// of the test folder. Each step is then screenshotted, in the screenshots/
// subfolder of the test folder.

const fs = require('fs');
const path = require('path');

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

// Returns the list of entries of all test folders, as objects
//   { dir, relDir, entry, name, html, steps }
// where html is the file to screenshot.
function findTests() {
    return findTestDirs(__dirname).flatMap(dir => {
        const relDir = path.relative(__dirname, dir);
        const runFile = path.join(dir, 'run.json');
        const config = JSON.parse(fs.readFileSync(runFile, 'utf8'));
        if (!Array.isArray(config))
            throw new Error(`${runFile}: expected a list of { entry, steps } objects`);
        return config.map(({ entry, steps = [0] }) => {
            if (typeof entry !== 'string')
                throw new Error(`${runFile}: missing "entry" field`);
            const name = path.parse(entry).name;
            const isHtml = path.extname(entry) === '.html';
            const html = path.join(dir, isHtml ? entry : `${name}.html`);
            return { dir, relDir, entry, name, html, steps };
        });
    });
}

module.exports = { findTests };
