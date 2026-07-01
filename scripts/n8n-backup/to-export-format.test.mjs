import { test } from 'node:test'
import assert from 'node:assert/strict'
import { toExportFormat } from './to-export-format.mjs'

test('toExportFormat keeps only the fields present in a manual n8n export', () => {
  const apiResponse = {
    updatedAt: '2026-06-29T23:30:10.958Z',
    createdAt: '2026-02-03T18:29:45.128Z',
    id: 'CPcP1m8sURQIOAGgCN8s0',
    name: 'WhatsApp Insurance Quotation Bot',
    description: null,
    active: true,
    isArchived: false,
    nodes: [{ name: 'Node A' }],
    connections: {},
    settings: { executionOrder: 'v1' },
    staticData: null,
    meta: { templateCredsSetupCompleted: true },
    pinData: {},
    versionId: 'abc',
    activeVersionId: 'abc',
    versionCounter: 1460,
    triggerCount: 2,
    shared: [{ project: { projectRelations: [{ user: { email: 'alfred@aguayo.co' } }] } }],
    tags: [],
    activeVersion: {},
  }
  const result = toExportFormat(apiResponse)
  assert.deepEqual(result, {
    name: 'WhatsApp Insurance Quotation Bot',
    nodes: [{ name: 'Node A' }],
    pinData: {},
    connections: {},
    active: true,
    settings: { executionOrder: 'v1' },
    versionId: 'abc',
    meta: { templateCredsSetupCompleted: true },
    id: 'CPcP1m8sURQIOAGgCN8s0',
    tags: [],
  })
})

test('toExportFormat never includes owner/sharing metadata even if present', () => {
  const apiResponse = { name: 'x', shared: [{ user: { email: 'leak@example.com' } }] }
  const result = toExportFormat(apiResponse)
  assert.equal('shared' in result, false)
  assert.equal(JSON.stringify(result).includes('leak@example.com'), false)
})

test('toExportFormat omits fields absent from the source response', () => {
  const result = toExportFormat({ name: 'minimal', nodes: [] })
  assert.deepEqual(result, { name: 'minimal', nodes: [] })
})
