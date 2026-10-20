// Uses temporary test accounts; never prints passwords or authentication tokens.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const project = 'habittracker-czh-20261020';
const key = fs.readFileSync('lib/firebase_options.dart', 'utf8').match(/apiKey: '([^']+)'/)[1];
const root = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const accounts = [];
async function request(url, body, token, method = 'POST') {
  const response = await fetch(url, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const data = await response.json();
  return { status: response.status, data };
}
function check(value, name) { if (!value) throw Error(name); console.log(`PASS ${name}`); }
async function auth(endpoint, body) {
  return request(`https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${key}`, body);
}
async function run() {
  const password = `Test9-${crypto.randomBytes(16).toString('hex')}`;
  try {
    for (let i = 0; i < 2; i++) {
      const email = `habittracker-test-${crypto.randomBytes(10).toString('hex')}@example.com`;
      const result = await auth('signUp', { email, password, returnSecureToken: true });
      check(result.status === 200, `Firebase email registration ${i + 1}`);
      accounts.push({ ...result.data, email });
    }
    const owner = accounts[0];
    const login = await auth('signInWithPassword', { email: owner.email, password, returnSecureToken: true });
    check(login.status === 200, 'Firebase email login');
    const duplicate = await auth('signUp', { email: owner.email, password, returnSecureToken: true });
    check(duplicate.status === 400, 'Duplicate registration rejected');
    const bad = await auth('signInWithPassword', { email: owner.email, password: 'WrongPassword9', returnSecureToken: true });
    check(bad.status === 400, 'Wrong password rejected');
    const name = `projects/${project}/databases/(default)/documents/users/${owner.localId}/state/main`;
    const write = (revision) => ({ writes: [{
      update: { name, fields: { revision: { integerValue: String(revision) }, payload: { stringValue: '{"test":true}' } } },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
    }] });
    const saved = await request(`${root}:commit`, write(1), owner.idToken);
    check(saved.status === 200, 'Owner can write Firestore');
    const read = await request(`${root}/users/${owner.localId}/state/main`, null, owner.idToken, 'GET');
    check(read.status === 200, 'Owner can read Firestore');
    const denied = await request(`${root}/users/${owner.localId}/state/main`, null, accounts[1].idToken, 'GET');
    check(denied.status === 403, 'Other account cannot read private data');
    const unauthenticated = await request(`${root}/users/${owner.localId}/state/main`, null, null, 'GET');
    check([401, 403].includes(unauthenticated.status), 'Unauthenticated access rejected');
    const stale = await request(`${root}:commit`, write(3), owner.idToken);
    check(stale.status === 403, 'Incorrect revision rejected');
    const next = await request(`${root}:commit`, write(2), owner.idToken);
    check(next.status === 200, 'Next revision accepted');
    const mediaRoot = `${root}/users/${owner.localId}/media/test-image`;
    const mediaWrite = await request(`${root}:commit`, {writes: [
      {update: {name: `${name.split('/state/')[0]}/media/test-image`, fields: {chunks: {integerValue: '1'}}}},
      {update: {name: `${name.split('/state/')[0]}/media/test-image/chunks/0`, fields: {data: {stringValue: 'aGVsbG8='}}}},
    ]}, owner.idToken);
    check(mediaWrite.status === 200, 'Owner can back up photo chunks');
    const mediaDenied = await request(`${mediaRoot}/chunks/0`, null, accounts[1].idToken, 'GET');
    check(mediaDenied.status === 403, 'Other account cannot read photos');
  } finally {
    const cliRoot = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
    const cliAuth = require(path.join(cliRoot, 'auth.js'));
    const options = { project };
    cliAuth.setActiveAccount(options, cliAuth.getGlobalDefaultAccount());
    await require(path.join(cliRoot, 'requireAuth.js')).requireAuth(options);
    const client = new (require(path.join(cliRoot, 'apiv2.js')).Client)({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
    for (const account of accounts) {
      for (const suffix of ['/media/test-image/chunks/0', '/media/test-image']) {
        try { await client.delete(`/projects/${project}/databases/(default)/documents/users/${account.localId}${suffix}`); }
        catch (error) { if (error.status !== 404) throw error; }
      }
      try { await client.delete(`/projects/${project}/databases/(default)/documents/users/${account.localId}/state/main`); }
      catch (error) { if (error.status !== 404) throw error; }
      const removed = await auth('delete', { idToken: account.idToken });
      check(removed.status === 200, 'Temporary test account removed');
    }
  }
}
run().catch(error => { console.error(`FAIL ${error.message}`); process.exitCode = 1; });
