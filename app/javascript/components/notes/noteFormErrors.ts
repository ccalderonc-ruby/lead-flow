export const NOTE_CREATE_ERROR_KEYS = [
  'content',
  'lead_id',
  'lead',
  'opportunity_id',
  'opportunity',
  'base',
  'form',
] as const

function hasTaskSpecificErrors(errors: Record<string, unknown>): boolean {
  return (
    errors.title != null ||
    errors.due_date != null ||
    errors.user_id != null ||
    errors.user != null
  )
}

function hasNoteFieldErrors(errors: Record<string, unknown>): boolean {
  return (
    errors.content != null ||
    errors.lead_id != null ||
    errors.lead != null ||
    errors.opportunity_id != null ||
    errors.opportunity != null ||
    errors.base != null
  )
}

export function hasNoteCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (errors.note_id != null) return false
  if (errors.form != null && String(Array.isArray(errors.form) ? errors.form[0] : errors.form) === 'note') {
    return hasNoteFieldErrors(errors)
  }
  if (errors.content != null) return true
  if (hasTaskSpecificErrors(errors)) return false
  return (
    errors.lead_id != null ||
    errors.lead != null ||
    errors.opportunity_id != null ||
    errors.opportunity != null ||
    errors.base != null
  )
}

export function hasNoteUpdateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (errors.note_id == null) return false
  return (
    hasNoteFieldErrors(errors) ||
    (errors.form != null && String(Array.isArray(errors.form) ? errors.form[0] : errors.form) === 'note')
  )
}

export function noteIdFromErrors(errors: Record<string, unknown> | undefined): number | null {
  if (!errors) return null
  const raw = errors.note_id
  const value = Array.isArray(raw) ? raw[0] : raw
  const id = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(id) ? id : null
}
