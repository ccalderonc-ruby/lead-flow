export const LEAD_CREATE_ERROR_KEYS = [
  'name',
  'email',
  'phone',
  'estimated_value',
  'company_name',
  'company_country_id',
  'country_id',
  'stage_id',
  'user_id',
  'user',
  'base',
  'form',
] as const

function isLeadFormMarker(errors: Record<string, unknown>): boolean {
  const form = errors.form
  if (form === 'lead') return true
  return Array.isArray(form) && form.includes('lead')
}

export function hasLeadCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (isLeadFormMarker(errors)) return true
  return ['name', 'email', 'company_name', 'company_country_id', 'country_id', 'stage_id'].some(
    (key) => errors[key] != null,
  )
}
