export const NOTE_CREATE_ERROR_KEYS = ['content', 'lead_id', 'lead', 'base'] as const

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
  if (errors.content != null) return true
  if (hasTaskSpecificErrors(errors)) return false
  return (['lead_id', 'lead', 'base'] as const).some((key) => errors[key] != null)
}
