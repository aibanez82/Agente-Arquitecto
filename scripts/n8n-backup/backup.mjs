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
