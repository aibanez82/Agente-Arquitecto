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
