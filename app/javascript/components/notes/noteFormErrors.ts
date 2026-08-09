export const NOTE_CREATE_ERROR_KEYS = ['content', 'lead_id', 'lead', 'base', 'form'] as const

function hasTaskSpecificErrors(errors: Record<string, unknown>): boolean {
  return (
    errors.title != null ||
    errors.due_date != null ||
    errors.user_id != null ||
    errors.user != null
  )
}

export function hasNoteCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (errors.note_id != null) return false
  if (errors.form != null && String(Array.isArray(errors.form) ? errors.form[0] : errors.form) === 'note') {
    return errors.content != null || errors.lead_id != null || errors.lead != null || errors.base != null
  }
  if (errors.content != null) return true
  if (hasTaskSpecificErrors(errors)) return false
  return (['lead_id', 'lead', 'base'] as const).some((key) => errors[key] != null)
}

export function hasNoteUpdateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  if (errors.note_id == null) return false
  return (
    errors.content != null ||
    errors.lead_id != null ||
    errors.lead != null ||
    errors.base != null ||
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
