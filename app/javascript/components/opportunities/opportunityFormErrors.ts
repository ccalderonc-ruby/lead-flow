export const OPPORTUNITY_UPDATE_ERROR_KEYS = [
  'title',
  'value',
  'stage_id',
  'stage',
  'close_date',
  'description',
  'base',
  'form',
  'opportunity_id',
] as const

function isOpportunityFormMarker(errors: Record<string, unknown>): boolean {
  const form = errors.form
  if (form === 'opportunity') return true
  return Array.isArray(form) && form.includes('opportunity')
}

export function hasOpportunityUpdateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (isOpportunityFormMarker(errors)) return true
  return OPPORTUNITY_UPDATE_ERROR_KEYS.some((key) => key !== 'form' && key !== 'opportunity_id' && errors[key] != null)
}

export function opportunityIdFromErrors(errors: Record<string, unknown> | undefined): number | null {
  if (!errors) return null
  const raw = errors.opportunity_id
  const value = Array.isArray(raw) ? raw[0] : raw
  const id = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(id) ? id : null
}
