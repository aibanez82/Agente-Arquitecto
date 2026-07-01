// Fields present in a manual n8n UI export ("Download"). The n8n REST API returns
// extra internal/owner metadata (e.g. shared.project.projectRelations[].user with the
// workflow owner's name and email) that must never be written to the repo.
const EXPORT_FIELDS = ['name', 'nodes', 'pinData', 'connections', 'active', 'settings', 'versionId', 'meta', 'id', 'tags']

export function toExportFormat(apiWorkflow) {
  const result = {}
  for (const field of EXPORT_FIELDS) {
    if (field in apiWorkflow) {
      result[field] = apiWorkflow[field]
    }
  }
  return result
}
