# n8n Workflow Backup Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automate backup of the 3 productive n8n workflows into this repo's git history so every change is diffable and rollback is "checkout an earlier commit's JSON and re-import in n8n UI."

**Architecture:** A dependency-free Node script fetches the workflow list from the n8n REST API, matches the 3 known workflows by name, fetches each full definition, and overwrites the corresponding file in `docs/n8n-workflows/`. A GitHub Actions workflow runs this script on a daily cron and on manual dispatch, then commits only if `git status` shows a diff (git itself acts as the "did anything change" check — no custom diffing needed).

**Tech Stack:** Node.js (>=18, built-in `fetch` and `node:test`, no npm dependencies), GitHub Actions.

## Global Constraints

- n8n API base URL: `https://n8n.srv1325340.hstgr.cloud/api/v1` (from CLAUDE.md).
- Auth header: `X-N8N-API-KEY` (from CLAUDE.md).
- Git identity for automated commits: `user.name = aibanez82`, `user.email = a.ibanez@gmail.com` (from CLAUDE.md conventions).
- Timezone: `America/Mexico_City`, always UTC-6, no DST (from CLAUDE.md conventions). Cron schedules must be written in UTC and account for this fixed offset.
- No new npm dependencies — repo currently has no `package.json`; keep the footprint dependency-free per YAGNI.
- The 3 target files already exist in `docs/n8n-workflows/` and must keep their exact current names:
  - `WhatsApp Insurance Quotation Bot.json`
  - `WhatsApp Insurance Quotation Bot - Payment Confirmation.json`
  - `Retomar Conversacion.json`
- Secrets (the n8n API key) must never be typed into chat/committed to the repo — Alberto sets the GitHub Actions secret directly via `gh` CLI or GitHub UI.

---

### Task 1: Workflow name→file matcher (pure function, TDD)

**Files:**
- Create: `scripts/n8n-backup/select-workflows.mjs`
- Test: `scripts/n8n-backup/select-workflows.test.mjs`
- Create: `package.json` (repo root)

**Interfaces:**
- Produces: `selectWorkflows(apiWorkflowList, workflowMap = WORKFLOW_MAP)` — takes the array returned by n8n's `GET /workflows` (`[{ id, name, ... }]`) and an optional override map, returns `[{ id, name, file }]` for each configured workflow found by exact name match. Throws `Error` with message `Workflow not found in n8n: "<name>"` if a configured name has no match.
- Produces: `WORKFLOW_MAP` — exported array of `{ name, file }` for the 3 productive workflows, used as the default map by `selectWorkflows` and reused by Task 2.

- [ ] **Step 1: Create `package.json` at repo root**

```json
{
  "name": "agente-arquitecto",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=18"
  },
  "scripts": {
    "test": "node --test",
    "backup:n8n": "node scripts/n8n-backup/backup.mjs"
  }
}
```

- [ ] **Step 2: Write the failing test**

```javascript
// scripts/n8n-backup/select-workflows.test.mjs
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { selectWorkflows } from './select-workflows.mjs'

test('selectWorkflows matches api workflows by exact name', () => {
  const apiList = [
    { id: 'abc123', name: 'WhatsApp Insurance Quotation Bot' },
    { id: 'def456', name: 'WhatsApp Insurance Quotation Bot - Payment Confirmation' },
    { id: 'ghi789', name: 'Retomar Conversacion' },
    { id: 'zzz999', name: 'Some Other Workflow' },
  ]
  const result = selectWorkflows(apiList)
  assert.deepEqual(result, [
    { id: 'abc123', name: 'WhatsApp Insurance Quotation Bot', file: 'WhatsApp Insurance Quotation Bot.json' },
    { id: 'def456', name: 'WhatsApp Insurance Quotation Bot - Payment Confirmation', file: 'WhatsApp Insurance Quotation Bot - Payment Confirmation.json' },
    { id: 'ghi789', name: 'Retomar Conversacion', file: 'Retomar Conversacion.json' },
  ])
})

test('selectWorkflows throws when a configured workflow name is not found', () => {
  const apiList = [{ id: 'abc123', name: 'WhatsApp Insurance Quotation Bot' }]
  assert.throws(
    () => selectWorkflows(apiList),
    /Workflow not found in n8n: "WhatsApp Insurance Quotation Bot - Payment Confirmation"/
  )
})

test('selectWorkflows accepts a custom workflow map', () => {
  const apiList = [{ id: 'x1', name: 'Custom Flow' }]
  const result = selectWorkflows(apiList, [{ name: 'Custom Flow', file: 'custom.json' }])
  assert.deepEqual(result, [{ id: 'x1', name: 'Custom Flow', file: 'custom.json' }])
})
```

- [ ] **Step 3: Run test to verify it fails**

Run: `node --test scripts/n8n-backup/select-workflows.test.mjs`
Expected: FAIL — cannot find module `./select-workflows.mjs`

- [ ] **Step 4: Write minimal implementation**

```javascript
// scripts/n8n-backup/select-workflows.mjs
export const WORKFLOW_MAP = [
  { name: 'WhatsApp Insurance Quotation Bot', file: 'WhatsApp Insurance Quotation Bot.json' },
  { name: 'WhatsApp Insurance Quotation Bot - Payment Confirmation', file: 'WhatsApp Insurance Quotation Bot - Payment Confirmation.json' },
  { name: 'Retomar Conversacion', file: 'Retomar Conversacion.json' },
]

export function selectWorkflows(apiWorkflowList, workflowMap = WORKFLOW_MAP) {
  return workflowMap.map(({ name, file }) => {
    const match = apiWorkflowList.find((w) => w.name === name)
    if (!match) {
      throw new Error(`Workflow not found in n8n: "${name}"`)
    }
    return { id: match.id, name, file }
  })
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `node --test scripts/n8n-backup/select-workflows.test.mjs`
Expected: PASS — 3 tests passing

- [ ] **Step 6: Commit**

```bash
git add package.json scripts/n8n-backup/select-workflows.mjs scripts/n8n-backup/select-workflows.test.mjs
git commit -m "feat: add n8n workflow name matcher for backup automation"
```

---

### Task 2: Backup script (n8n API I/O)

**Files:**
- Create: `scripts/n8n-backup/backup.mjs`

**Interfaces:**
- Consumes: `selectWorkflows`, `WORKFLOW_MAP` from `./select-workflows.mjs` (Task 1).
- Produces: `backupWorkflows()` async function that writes each matched workflow's full JSON to `docs/n8n-workflows/<file>`, and a CLI entry point (`node scripts/n8n-backup/backup.mjs`) that calls it and exits non-zero on failure.

This task has no automated unit test — it performs real I/O against a live external API and the filesystem, which is exactly what Task 1 factored out into a pure, tested function. Verification here is manual (Step 3).

- [ ] **Step 1: Write the script**

```javascript
// scripts/n8n-backup/backup.mjs
import { writeFile } from 'node:fs/promises'
import path from 'node:path'
import { selectWorkflows } from './select-workflows.mjs'

const N8N_BASE_URL = process.env.N8N_BASE_URL ?? 'https://n8n.srv1325340.hstgr.cloud/api/v1'
const OUTPUT_DIR = path.join(import.meta.dirname, '..', '..', 'docs', 'n8n-workflows')

async function n8nFetch(apiPath) {
  const res = await fetch(`${N8N_BASE_URL}${apiPath}`, {
    headers: { 'X-N8N-API-KEY': process.env.N8N_API_KEY },
  })
  if (!res.ok) {
    throw new Error(`n8n API ${apiPath} -> ${res.status} ${await res.text()}`)
  }
  return res.json()
}

async function fetchAllWorkflows() {
  const workflows = []
  let cursor
  do {
    const query = cursor ? `?cursor=${encodeURIComponent(cursor)}` : ''
    const page = await n8nFetch(`/workflows${query}`)
    workflows.push(...page.data)
    cursor = page.nextCursor
  } while (cursor)
  return workflows
}

export async function backupWorkflows() {
  if (!process.env.N8N_API_KEY) {
    throw new Error('N8N_API_KEY env var is required')
  }
  const list = await fetchAllWorkflows()
  const targets = selectWorkflows(list)
  for (const target of targets) {
    const full = await n8nFetch(`/workflows/${target.id}`)
    const outPath = path.join(OUTPUT_DIR, target.file)
    await writeFile(outPath, JSON.stringify(full, null, 2) + '\n', 'utf8')
    console.log(`Wrote ${target.file}`)
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  backupWorkflows().catch((err) => {
    console.error(err)
    process.exitCode = 1
  })
}
```

- [ ] **Step 2: Run the existing test suite to make sure nothing broke**

Run: `npm test`
Expected: PASS — the 3 tests from Task 1 still pass (this file adds no new tests, just confirm no regression)

- [ ] **Step 3: Manual verification (Alberto runs this — requires the real N8N_API_KEY)**

```bash
node --env-file=.env scripts/n8n-backup/backup.mjs
```

Create a local `.env` (already gitignored) with `N8N_API_KEY=<the real key>` first. Expected output: 3 lines like `Wrote WhatsApp Insurance Quotation Bot.json`, and `git diff docs/n8n-workflows/` shows the caso-001/caso-002 changes that were applied directly in production and never exported (this run also closes that separate pendiente).

If a workflow name doesn't match (script throws `Workflow not found in n8n: "..."`), the workflow was renamed in n8n — update `WORKFLOW_MAP` in `select-workflows.mjs` to the current name and re-run.

- [ ] **Step 4: Commit**

```bash
git add scripts/n8n-backup/backup.mjs
git commit -m "feat: add n8n workflow backup script"
```

(Commit the resulting `docs/n8n-workflows/*.json` diff from Step 3 separately, with its own message, since that's a data update rather than a tooling change — e.g. `docs: re-exportar workflow n8n con cambios caso-001/caso-002`.)

---

### Task 3: GitHub Actions automation

**Files:**
- Create: `.github/workflows/backup-n8n.yml`

**Interfaces:**
- Consumes: `npm test` and `npm run backup:n8n` from `package.json` (Task 1/2), secret `N8N_API_KEY`.

- [ ] **Step 1: Write the workflow file**

```yaml
name: Backup n8n workflows

on:
  schedule:
    - cron: '0 12 * * *' # 06:00 America/Mexico_City (UTC-6, no DST)
  workflow_dispatch: {}

permissions:
  contents: write

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm test

      - run: npm run backup:n8n
        env:
          N8N_API_KEY: ${{ secrets.N8N_API_KEY }}

      - name: Commit changes if any
        run: |
          git config user.name "aibanez82"
          git config user.email "a.ibanez@gmail.com"
          if [ -n "$(git status --porcelain docs/n8n-workflows/)" ]; then
            git add docs/n8n-workflows/
            git commit -m "chore: backup automático workflow n8n ($(date -u +%Y-%m-%d))"
            git push
          else
            echo "No changes, skipping commit"
          fi
```

- [ ] **Step 2: Validate YAML syntax locally**

Run: `python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/backup-n8n.yml'))" && echo OK`
Expected: `OK` (this only checks the file parses as valid YAML, not that the job succeeds — actual execution is verified in Task 4)

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/backup-n8n.yml
git commit -m "ci: add scheduled n8n workflow backup action"
```

---

### Task 4: Activate in GitHub (Alberto executes — needs repo secret access)

These steps touch GitHub Actions secrets and must be run by Alberto directly; the key should never be pasted into this conversation.

- [ ] **Step 1: Push the branch / merge to main**

```bash
git push
```

- [ ] **Step 2: Set the secret** (prompts interactively, key never appears in shell history or chat)

```bash
gh secret set N8N_API_KEY --repo aibanez82/Agente-Arquitecto
```

- [ ] **Step 3: Trigger a manual run**

```bash
gh workflow run backup-n8n.yml --repo aibanez82/Agente-Arquitecto
```

- [ ] **Step 4: Verify the run succeeded and check for a commit**

```bash
gh run watch --repo aibanez82/Agente-Arquitecto
git pull
git log --oneline -3
```

Expected: either a new `chore: backup automático workflow n8n (...)` commit (if production had drifted from the repo) or the run completes with "No changes, skipping commit" logged (if the repo was already in sync).

---

## Manual export discipline (until this is proven stable)

Per `docs/architecture/backup-policy-n8n.md`, until a few scheduled runs have been verified working, keep exporting manually via `gh workflow run backup-n8n.yml` **before** any system-prompt change in n8n UI — don't rely solely on the daily cron for pre-change safety.
