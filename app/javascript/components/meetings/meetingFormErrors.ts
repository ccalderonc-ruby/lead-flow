export const MEETING_CREATE_ERROR_KEYS = [
  'title',
  'scheduled_on',
  'start_time',
  'lead_id',
  'lead',
  'user_id',
  'user',
  'location',
  'virtual_link',
  'virtual_meeting',
  'status',
  'base',
  'form',
] as const

function isMeetingFormMarker(errors: Record<string, unknown>): boolean {
  const form = errors.form
  if (form === 'meeting') return true
  return Array.isArray(form) && form.includes('meeting')
}

export function hasMeetingCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (isMeetingFormMarker(errors)) return true
  return ['scheduled_on', 'start_time', 'location', 'virtual_link', 'virtual_meeting'].some(
    (key) => errors[key] != null,
  )
}
