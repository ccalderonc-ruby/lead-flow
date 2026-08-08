export const TASK_CREATE_ERROR_KEYS = [
  'title',
  'description',
  'due_date',
  'status',
  'lead_id',
  'lead',
  'user_id',
  'user',
  'base',
] as const

export function hasTaskCreateErrors(errors: Record<string, unknown> | undefined): boolean {
  if (!errors) return false
  return TASK_CREATE_ERROR_KEYS.some((key) => errors[key] != null)
}
