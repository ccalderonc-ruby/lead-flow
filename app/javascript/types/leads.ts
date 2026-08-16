import type {
  MeetingFormDefaults,
  MeetingFormOption,
} from '@/components/meetings/MeetingFormModal'
import type { NoteFormOption } from '@/components/notes/NoteFormModal'
import type {
  OpportunityFormDefaults,
  OpportunityFormOption,
} from '@/components/opportunities/OpportunityFormModal'
import type { TaskFormDefaults, TaskFormOption } from '@/components/tasks/TaskFormModal'

export type LeadDetail = {
  id: number
  name: string
  email: string
  phone: string | null
  estimated_value: string | number | null
  last_activity_at: string | null
  company: string | null
  country: string | null
  stage: string | null
  advisor: string | null
  can_update: boolean
}

export type TaskPreview = {
  id: number
  title: string
  description?: string | null
  due_date: string | null
  status: string | null
  past_due?: boolean
  completed_at?: string | null
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
}

export type MeetingPreview = {
  id: number
  title: string
  scheduled_on: string | null
  start_time?: string | null
  location?: string | null
  virtual_link?: string | null
  virtual_meeting?: boolean | null
  video_provider?: string | null
  external_meeting_id?: string | null
  status: string | null
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
}

export type NotePreview = {
  id: number
  content: string
  author: string | null
  created_at: string | null
  can_update: boolean
  can_destroy: boolean
}

export type OpportunityPreview = {
  id: number
  title: string
  value: string | number | null
  stage: string | null
}

export type RelatedSection<T> = {
  count: number
  items: T[]
}

export type NotesSection = RelatedSection<NotePreview> & {
  showing: number
  truncated: boolean
}

export type TaskFormProps = {
  leads: TaskFormOption[]
  assignees: TaskFormOption[]
  defaults: TaskFormDefaults
  return_to: string
}

export type MeetingFormProps = {
  leads: MeetingFormOption[]
  hosts: MeetingFormOption[]
  defaults: MeetingFormDefaults
  return_to: string
}

export type NoteFormProps = {
  lead_id: number
  leads?: NoteFormOption[]
  return_to: string
}

export type OpportunityFormProps = {
  leads: OpportunityFormOption[]
  stages: OpportunityFormOption[]
  defaults: OpportunityFormDefaults
  return_to: string
}

export type LeadsShowProps = {
  lead: LeadDetail
  tasks: RelatedSection<TaskPreview>
  meetings: RelatedSection<MeetingPreview>
  notes: NotesSection
  opportunities: RelatedSection<OpportunityPreview>
  can_create_task: boolean
  task_form: TaskFormProps
  can_create_meeting: boolean
  meeting_form: MeetingFormProps
  can_create_note: boolean
  can_email: boolean
  note_form: NoteFormProps
  can_create_opportunity: boolean
  opportunity_form: OpportunityFormProps
}
