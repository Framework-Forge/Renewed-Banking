const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const read = file => new TextDecoder('utf-8', { fatal: true }).decode(fs.readFileSync(file));
const dictionaries = Object.fromEntries(fs.readdirSync(path.join(root, 'locales')).filter(f => f.endsWith('.json'))
    .map(f => [f, JSON.parse(read(path.join(root, 'locales', f)))]));
const reference = dictionaries['en.json'];
const required = new Set(Object.keys(reference));
function files(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e =>
        e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]);
}
const sources = [...files(path.join(root, 'web/src')), ...files(path.join(root, 'client')), ...files(path.join(root, 'server'))];
for (const file of sources.filter(f => /\.(lua|ts|svelte)$/.test(f))) {
    const source = read(file);
    assert(!source.includes('\uFFFD'), `Corrupt UTF-8 text: ${file}`);
    for (const match of source.matchAll(/\b(?:text|locale)\(\s*['"]([\w-]+)['"]\s*[,)]/g)) required.add(match[1]);
    for (const match of source.matchAll(/\$translations\.([\w]+)/g)) required.add(match[1]);
    assert(!/text\(\s*['"][\w-]+['"]\s*,\s*['"]/.test(source), `Hardcoded translation fallback: ${file}`);
}
const formats = ['invoice_transaction', 'invoice_refund', 'bank_message_transaction', 'bank_message_balance', 'bank_message_reason'];
for (const [name, dictionary] of Object.entries(dictionaries)) {
    assert.deepEqual(Object.keys(dictionary).sort(), Object.keys(reference).sort(), `Key mismatch: ${name}`);
    for (const key of required) {
        assert(typeof dictionary[key] === 'string' && dictionary[key].trim(), `Missing ${key} in ${name}`);
        assert(!dictionary[key].includes('\uFFFD'), `Corrupt text: ${name}:${key}`);
    }
    for (const key of formats) {
        assert.equal((dictionary[key].match(/%s/g) || []).length, (reference[key].match(/%s/g) || []).length, `Placeholder mismatch: ${name}:${key}`);
    }
}
console.log(`PASS: ${Object.keys(dictionaries).length} UTF-8 catalogs; ${required.size} required keys; locale parity and message placeholders`);
