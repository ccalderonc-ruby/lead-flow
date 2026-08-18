# frozen_string_literal: true

class DashboardController < InertiaController
  SESSION_VIEW_KEY = :dashboard_view
  SESSION_ADVISOR_KEY = :dashboard_advisor_id
  SESSION_ACTIVITY_DAYS_KEY = :dashboard_activity_days
  SESSION_LEAD_STAGE_KEY = :dashboard_lead_stage_id

  def index
    authorize :dashboard, :index?

    subject, view, selected_advisor = resolve_dashboard_context
    activity_days = resolve_activity_days
    lead_stage_id = resolve_lead_stage_id
    payload = DashboardMetrics.new(
      subject,
      activity_days: activity_days,
      lead_stage_id: lead_stage_id,
      book_only: view == "advisor"
    ).call
    lead_options = form_lead_options
    first_session = session.delete(:first_session)

    render inertia: "dashboard/index", props: {
      metrics: payload[:metrics],
      upcoming_activities: payload[:upcoming_activities],
      recent_leads: payload[:recent_leads],
      pipeline_stages: payload[:pipeline_stages],
      activity_days: payload[:activity_days],
      activity_day_options: payload[:activity_day_options],
      lead_stage_id: payload[:lead_stage_id],
      lead_stage_options: payload[:lead_stage_options],
      view: view,
      can_switch_view: policy(:dashboard).view_organization?,
      advisors: advisor_options,
      selected_advisor_id: selected_advisor&.id,
      selected_advisor_name: selected_advisor&.name,
      greeting: {
        name: current_user.name,
        first_name: current_user.name.to_s.split(/\s+/).first,
        role_label: role_label_for(view, selected_advisor),
        date_label: Time.zone.today.strftime("%A, %B %-d, %Y"),
        first_session: first_session == true
      },
      onboarding: onboarding_props(subject),
      actions: {
        can_create_lead: policy(Lead).create?,
        can_create_task: can_create_tasks?,
        can_create_meeting: can_create_meetings?,
        can_create_note: can_create_notes?
      },
      forms: {
        lead: lead_form_props,
        task: {
          leads: lead_options,
          assignees: task_assignees_for_form,
          defaults: {
            user_id: default_task_assignee_id,
            force_assignee: !current_user.admin? && !current_user.assistant?
          }
        },
        meeting: {
          leads: lead_options,
          hosts: meeting_hosts_for_form,
          defaults: {
            user_id: default_meeting_host_id,
            force_host: !current_user.admin?
          }
        },
        note: {
          leads: lead_options,
          opportunities: note_opportunity_options
        }
      }
    }
  end

  private

  def onboarding_props(subject)
    empty = LeadPolicy::Scope.new(subject, Lead).resolve.none?
    return { show: false } unless empty

    role = current_user.role.name
    {
      show: true,
      title: onboarding_title(role),
      description: onboarding_description(role),
      checklist: onboarding_checklist(role),
      primary_action: onboarding_primary_action(role),
      secondary_action: onboarding_secondary_action(role)
    }
  end

  def onboarding_title(role)
    case role
    when "admin", "billing_admin"
      "Set up your team’s pipeline"
    when "assistant"
      "You’re ready to support advisors"
    else
      "Create your first lead"
    end
  end

  def onboarding_description(role)
    case role
    when "admin", "billing_admin"
      "Your organization doesn’t have any leads yet. Add a prospect or invite teammates so advisors can start working."
    when "assistant"
      "No leads are in your assigned scope yet. Once an advisor adds prospects, they’ll show up here for you to help with."
    else
      "Your pipeline is empty. Add a prospect to start tracking follow-ups, meetings, and opportunities."
    end
  end

  def onboarding_checklist(role)
    case role
    when "admin", "billing_admin"
      [
        { id: "users", label: "Review teammates under Users", href: "/admin/users", done: false },
        { id: "lead", label: "Create your first lead", action: "create_lead", done: false },
        { id: "pipeline", label: "Open the Opportunities board when deals appear", href: "/opportunities", done: false }
      ]
    when "assistant"
      [
        { id: "leads", label: "Browse leads for your assigned advisors", href: "/leads", done: false },
        { id: "tasks", label: "Check tasks you can help complete", href: "/tasks", done: false },
        { id: "notes", label: "Add notes as conversations happen", href: "/notes", done: false }
      ]
    else
      [
        { id: "lead", label: "Create your first lead", action: "create_lead", done: false },
        { id: "follow_up", label: "Schedule a task or meeting from the lead", href: "/leads", done: false },
        { id: "opportunity", label: "Track a deal on the Opportunities board", href: "/opportunities", done: false }
      ]
    end
  end

  def onboarding_primary_action(role)
    if role == "assistant"
      { label: "View leads", href: "/leads" }
    elsif policy(Lead).create?
      { label: "Create lead", action: "create_lead" }
    else
      { label: "View leads", href: "/leads" }
    end
  end

  def onboarding_secondary_action(role)
    case role
    when "admin", "billing_admin"
      { label: "Manage users", href: "/admin/users" }
    when "assistant"
      { label: "View tasks", href: "/tasks" }
    else
      { label: "Browse leads", href: "/leads" }
    end
  end

  def resolve_activity_days
    requested = Array(params[:activity_days]).first.presence || session[SESSION_ACTIVITY_DAYS_KEY]
    days = DashboardMetrics.normalize_activity_days(requested)
    session[SESSION_ACTIVITY_DAYS_KEY] = days
    days
  end

  def resolve_lead_stage_id
    raw =
      if params.key?(:lead_stage_id)
        Array(params[:lead_stage_id]).first
      else
        session[SESSION_LEAD_STAGE_KEY]
      end

    stage_id = DashboardMetrics.normalize_lead_stage_id(raw)
    if stage_id
      session[SESSION_LEAD_STAGE_KEY] = stage_id
    else
      session.delete(SESSION_LEAD_STAGE_KEY)
    end
    stage_id
  end

  def resolve_dashboard_context
    unless current_user.admin?
      return [ current_user, "personal", nil ]
    end

    requested_view = Array(params[:view]).first.presence || session[SESSION_VIEW_KEY]
    view = %w[organization advisor].include?(requested_view) ? requested_view : "organization"

    if view == "advisor"
      authorize :dashboard, :view_as_advisor?
      advisor = find_team_advisor(params[:advisor_id] || session[SESSION_ADVISOR_KEY])
      advisor ||= team_advisors.first

      if advisor
        session[SESSION_VIEW_KEY] = "advisor"
        session[SESSION_ADVISOR_KEY] = advisor.id
        return [ advisor, "advisor", advisor ]
      end
    end

    authorize :dashboard, :view_organization?
    session[SESSION_VIEW_KEY] = "organization"
    session.delete(SESSION_ADVISOR_KEY)
    [ current_user, "organization", nil ]
  end

  def find_team_advisor(raw_id)
    id = Integer(Array(raw_id).first, exception: false)
    return nil unless id

    team_advisors.find_by(id: id)
  end

  def team_advisors
    User.joins(:role)
      .includes(:role)
      .on_team(current_user.team)
      .where(roles: { name: %w[billing_admin admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name, :id)
  end

  def advisor_options
    return [] unless current_user.admin?

    team_advisors.map { |user|
      {
        id: user.id,
        name: user.name,
        role: user.role.name
      }
    }
  end

  def role_label_for(view, selected_advisor)
    case view
    when "organization"
      "Organization"
    when "advisor"
      selected_advisor&.name || "Advisor"
    else
      current_user.role.name.tr("_", " ").split.map(&:capitalize).join(" ")
    end
  end

  def can_create_tasks?
    return true if current_user.admin? || current_user.assistant?

    current_user.advisor? && policy_scope(Lead).exists?
  end

  def can_create_meetings?
    return true if current_user.admin?

    current_user.advisor? && policy_scope(Lead).exists?
  end

  def can_create_notes?
    return true if current_user.admin?
    return true if current_user.assistant? && (policy_scope(Lead).exists? || policy_scope(Opportunity).exists?)

    current_user.advisor? && (policy_scope(Lead).exists? || policy_scope(Opportunity).exists?)
  end

  def lead_form_props
    {
      countries: Country.order(:name).map { |country| { id: country.id, name: country.name } },
      stages: LeadStage.order(:position).map { |stage| { id: stage.id, name: stage.name } },
      assignees: lead_assignees_for_form,
      defaults: {
        user_id: current_user.admin? ? nil : current_user.id,
        force_assignee: !current_user.admin?
      }
    }
  end

  def form_lead_options
    policy_scope(Lead).order(:name).map { |lead| { id: lead.id, name: lead.name } }
  end

  def note_opportunity_options
    policy_scope(Opportunity).includes(:lead).order(:title).map { |opportunity|
      {
        id: opportunity.id,
        name: opportunity.title.presence || "Untitled",
        lead_name: opportunity.lead&.name
      }
    }
  end

  def lead_assignees_for_form
    return [] unless current_user.admin?

    assignable_crm_users.map { |user| { id: user.id, name: user.name } }
  end

  def task_assignees_for_form
    return [ { id: current_user.id, name: current_user.name } ] if current_user.advisor?

    assignable_crm_users.map { |user| { id: user.id, name: user.name } }
  end

  def meeting_hosts_for_form
    return [ { id: current_user.id, name: current_user.name } ] if current_user.advisor?

    assignable_crm_users.map { |user| { id: user.id, name: user.name } }
  end

  def assignable_crm_users
    User.joins(:role)
      .where(roles: { name: %w[billing_admin admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def default_task_assignee_id
    return current_user.id if current_user.advisor?

    task_assignees_for_form.first&.fetch(:id)
  end

  def default_meeting_host_id
    return current_user.id if current_user.advisor?

    meeting_hosts_for_form.first&.fetch(:id)
  end
end
