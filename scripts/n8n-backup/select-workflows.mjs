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
