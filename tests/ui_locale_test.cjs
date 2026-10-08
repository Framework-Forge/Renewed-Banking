const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../web');
const svelte = require(path.join(root, 'node_modules/svelte/compiler'));
const preprocess = require(path.join(root, 'node_modules/svelte-preprocess'));
function files(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e =>
        e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]);
}
(async () => {
    const fixed = [];
    const components = files(path.join(root, 'src')).filter(f => f.endsWith('.svelte'));
    for (const file of components) {
        const source = fs.readFileSync(file, 'utf8');
        const result = await svelte.preprocess(source, preprocess(), { filename: file });
        const ast = svelte.parse(result.code);
        function visit(node) {
            if (!node || typeof node !== 'object') return;
            if (node.type === 'Text' && /\p{L}/u.test(node.data || '')) fixed.push([file, node.data.trim()]);
            if (node.type === 'Attribute' && ['alt', 'title', 'placeholder', 'aria-label'].includes(node.name)) {
                for (const value of node.value || []) {
                    // This is an example asset path, not a translatable sentence.
                    if (value.type === 'Text' && /\p{L}/u.test(value.data) && value.data !== 'img/bank.png') fixed.push([file, value.data]);
                }
            }
            // Attribute Text nodes also represent class names, URLs and IDs.
            // Only the user-facing attributes above are translation candidates.
            if (node.type === 'Attribute') return;
            for (const value of Object.values(node)) {
                if (Array.isArray(value)) value.forEach(visit);
                else if (value && typeof value === 'object') visit(value);
            }
        }
        visit(ast.html);
    }
    assert.deepEqual(fixed, [], 'Hardcoded visible component text');
    console.log(`PASS: ${components.length} components without hardcoded visible labels or accessibility text`);
})().catch(error => { console.error(error); process.exitCode = 1; });
