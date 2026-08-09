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

export const OPPORTUNITY_CREATE_ERROR_KEYS = [
  'title',
  'value',
  'stage_id',
  'stage',
  'close_date',
  'description',
  'lead_id',
  'lead',
  'base',
  'form',
] as const

function isOpportunityFormMarker(errors: Record<string, unknown>): boolean {
  const form = errors.form
  if (form === 'opportunity') return true
  return Array.isArray(form) && form.includes('opportunity')
}

export function opportunityIdFromErrors(errors: Record<string, unknown> | undefined): number | null {
  if (!errors) return null
  const raw = errors.opportunity_id
  const value = Array.isArray(raw) ? raw[0] : raw
  const id = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(id) ? id : null
}

/** Update drawer errors always include opportunity_id. */
export function hasOpportunityUpdateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  return opportunityIdFromErrors(errors) != null
}

/** Create modal errors use form:opportunity without opportunity_id. */
export function hasOpportunityCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (opportunityIdFromErrors(errors) != null) return false
  if (isOpportunityFormMarker(errors)) return true
  return ['lead_id', 'lead'].some((key) => errors[key] != null)
}
