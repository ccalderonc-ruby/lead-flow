# frozen_string_literal: true

class DashboardMetrics
  ACTIVITY_LIMIT = 8
  RECENT_LEADS_LIMIT = 5
  ACTIVITY_DAY_OPTIONS = [ 0, 3, 7, 14, 30 ].freeze
  DEFAULT_ACTIVITY_DAYS = 7

  def self.normalize_activity_days(raw)
    days = Integer(raw, exception: false)
    return DEFAULT_ACTIVITY_DAYS unless days && ACTIVITY_DAY_OPTIONS.include?(days)

    days
  end

  def self.normalize_lead_stage_id(raw)
    id = Integer(raw, exception: false)
    return nil unless id
    return nil unless LeadStage.exists?(id)

    id
  end

  def initialize(user, activity_days: DEFAULT_ACTIVITY_DAYS, lead_stage_id: nil)
    @user = user
    @activity_days = self.class.normalize_activity_days(activity_days)
    @lead_stage_id = self.class.normalize_lead_stage_id(lead_stage_id)
  end

  def call
    {
      metrics: metrics,
      upcoming_activities: upcoming_activities,
      recent_leads: recent_leads,
      pipeline_stages: pipeline_stages,
      activity_days: activity_days,
      activity_day_options: ACTIVITY_DAY_OPTIONS,
      lead_stage_id: lead_stage_id,
      lead_stage_options: lead_stage_options
    }
  end

  private

  attr_reader :user, :activity_days, :lead_stage_id

  def metrics
    today_meetings = scoped_meetings.merge(meetings_on(Date.current)).includes(:lead).order(:start_time, :id)
    next_meeting = today_meetings.first
    due_today = scoped_tasks.merge(Task.open_status).where(due_date: Date.current)

    {
      open_leads: scoped_leads.merge(Lead.open).count,
      active_opportunities: scoped_opportunities.merge(Opportunity.active_pipeline).count,
      tasks_due_today: due_today.count,
      high_priority_tasks_due_today: due_today.where(priority: "high").count,
      meetings_today: today_meetings.count,
      next_meeting_time: format_clock_time(next_meeting&.start_time),
      overdue_tasks: scoped_tasks.merge(Task.overdue).count,
      upcoming_meetings: scoped_meetings.merge(Meeting.upcoming).count,
      pipeline_value: scoped_opportunities.merge(Opportunity.active_pipeline).sum(:value).to_f
    }
  end

  def upcoming_activities
    window = activity_date_window

    meeting_rows = scoped_meetings
      .where(status: Meeting.statuses[:scheduled], scheduled_on: window)
      .includes(:lead)
      .order(:scheduled_on, :start_time, :id)
      .limit(ACTIVITY_LIMIT)
      .map { |meeting| serialize_meeting_activity(meeting) }

    task_rows = scoped_tasks
      .merge(Task.open_status)
      .where(due_date: window)
      .includes(:lead)
      .order(:due_date, :id)
      .limit(ACTIVITY_LIMIT)
      .map { |task| serialize_task_activity(task) }

    (meeting_rows + task_rows)
      .sort_by { |row| [ row[:sort_date], row[:sort_time], row[:id] ] }
      .first(ACTIVITY_LIMIT)
      .map { |row| row.except(:sort_date, :sort_time) }
  end

  def activity_date_window
    Date.current..(Date.current + activity_days.days)
  end

  def recent_leads
    scope = scoped_leads.includes(:company, :stage, :user)
    scope = scope.where(stage_id: lead_stage_id) if lead_stage_id
    scope
      .order(updated_at: :desc, id: :desc)
      .limit(RECENT_LEADS_LIMIT)
      .map do |lead|
        {
          id: lead.id,
          name: lead.name,
          company: lead.company&.name,
          stage: lead.stage&.name,
          owner: lead.user&.name
        }
      end
  end

  def lead_stage_options
    LeadStage.order(:position).map { |stage| { id: stage.id, name: stage.name } }
  end

  def pipeline_stages
    active = scoped_opportunities.merge(Opportunity.active_pipeline)
    stages = OpportunityStage.order(:position).reject { |stage| stage.name.in?(%w[Won Lost]) }

    stages.map do |stage|
      stage_scope = active.where(stage_id: stage.id)
      {
        id: stage.id,
        name: stage.name,
        count: stage_scope.count,
        value: stage_scope.sum(:value).to_f
      }
    end
  end

  def serialize_meeting_activity(meeting)
    {
      id: meeting.id,
      kind: "meeting",
      title: meeting.title,
      when_label: activity_when_label(meeting.scheduled_on, meeting.start_time),
      lead_name: meeting.lead&.name,
      virtual_link: meeting.virtual_link.presence,
      can_complete: false,
      can_edit: MeetingPolicy.new(user, meeting).update?,
      can_revert: terminal_meeting?(meeting) && MeetingPolicy.new(user, meeting).revert?,
      lead_id: meeting.lead_id,
      user_id: meeting.user_id,
      status: meeting.status,
      scheduled_on: meeting.scheduled_on&.iso8601,
      start_time: format_meeting_start_time(meeting.start_time),
      location: meeting.location,
      virtual_meeting: meeting.virtual_meeting,
      sort_date: meeting.scheduled_on,
      sort_time: meeting.start_time&.strftime("%H%M%S") || "000000"
    }
  end

  def serialize_task_activity(task)
    {
      id: task.id,
      kind: "task",
      title: task.title,
      when_label: activity_when_label(task.due_date, nil),
      lead_name: task.lead&.name,
      virtual_link: nil,
      can_complete: !task.completed?,
      can_edit: TaskPolicy.new(user, task).update?,
      can_revert: task.completed? && TaskPolicy.new(user, task).revert?,
      lead_id: task.lead_id,
      user_id: task.user_id,
      status: display_task_status(task),
      description: task.description,
      due_date: task.due_date&.iso8601,
      sort_date: task.due_date,
      sort_time: "235959"
    }
  end

  def display_task_status(task)
    task.status == Task.statuses[:overdue] ? Task.statuses[:pending] : task.status
  end

  def format_meeting_start_time(value)
    return if value.blank?

    value.strftime("%H:%M")
  end

  def terminal_meeting?(meeting)
    meeting.status.to_s.in?([ Meeting.statuses[:completed], Meeting.statuses[:cancelled] ])
  end

  def activity_when_label(date, time)
    day =
      if date == Date.current
        nil
      elsif date == Date.current + 1.day
        "Tomorrow"
      else
        date.strftime("%b %-d")
      end

    clock = format_clock_time(time)
    return day if clock.blank?
    return clock if day.blank?

    "#{day} #{clock}"
  end

  def format_clock_time(time)
    return nil if time.blank?

    time.in_time_zone.strftime("%-I:%M %p")
  end

  def meetings_on(date)
    Meeting.where(status: Meeting.statuses[:scheduled], scheduled_on: date)
  end

  def scoped_leads
    LeadPolicy::Scope.new(user, Lead).resolve
  end

  def scoped_tasks
    TaskPolicy::Scope.new(user, Task).resolve
  end

  def scoped_meetings
    MeetingPolicy::Scope.new(user, Meeting).resolve
  end

  def scoped_opportunities
    OpportunityPolicy::Scope.new(user, Opportunity).resolve
  end
end
