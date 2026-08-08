# frozen_string_literal: true

class TasksController < InertiaController
  PER_PAGE = 25
  FILTERS = %w[all mine pending completed overdue].freeze

  before_action :set_task, only: :update

  def index
    authorize Task

    requested_filter = Array(params[:filter]).first.to_s
    if requested_filter.present? && FILTERS.exclude?(requested_filter)
      redirect_to tasks_path(page: Array(params[:page]).first.presence)
      return
    end

    filter = FILTERS.include?(requested_filter) ? requested_filter : "all"

    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    scoped = apply_filter(policy_scope(Task), filter)
    total_count = scoped.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    tasks = scoped
      .includes(:lead, :user)
      .order(:due_date, :id)
      .offset((page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    render inertia: "tasks/index", props: {
      tasks: tasks.map { |task| serialize_task(task) },
      meta: {
        filter: filter,
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        total_pages: total_pages
      },
      **form_options,
      can_create: can_create_tasks?,
      return_to: tasks_return_path(filter, page)
    }
  end

  def create
    lead = policy_scope(Lead).find_by(id: task_create_params[:lead_id])
    unless lead
      skip_authorization
      redirect_to safe_return_path, inertia: { errors: lead_missing_errors }
      return
    end

    task = Task.new(lead: lead)
    authorize task

    task.assign_attributes(
      title: task_create_params[:title],
      due_date: task_create_params[:due_date],
      user_id: assigned_user_id(lead),
      status: :pending
    )

    if task.save
      flash[:notice] = "Task created."
      redirect_to safe_return_path
    else
      redirect_to safe_return_path, inertia: { errors: validation_errors(task) }
    end
  end

  def update
    authorize @task

    if complete_only_request?
      complete_task!
    else
      update_task_fields!
    end
  end

  private

  def set_task
    @task = policy_scope(Task).includes(:lead).find(params[:id])
  end

  def apply_filter(scoped, filter)
    case filter
    when "mine"
      scoped.where(user_id: current_user.id)
    when "pending"
      scoped.merge(Task.open_status)
    when "completed"
      scoped.merge(Task.completed_status)
    when "overdue"
      scoped.merge(Task.overdue)
    else
      scoped
    end
  end

  def serialize_task(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      lead: task.lead&.name,
      lead_id: task.lead_id,
      due_date: task.due_date&.iso8601,
      status: display_status(task),
      past_due: past_due?(task),
      completed_at: task.completed_at&.iso8601,
      assignee: task.user&.name,
      user_id: task.user_id,
      can_edit: policy(task).update?,
      can_revert: can_revert?(task)
    }
  end

  # Overdue is date-derived in the UI; do not expose it as a workflow status.
  def display_status(task)
    task.status == Task.statuses[:overdue] ? Task.statuses[:pending] : task.status
  end

  def past_due?(task)
    return false if task.completed? || task.due_date.blank?

    task.due_date < Date.current
  end

  def can_revert?(task)
    task.completed? && policy(task).revert?
  end

  def complete_only_request?
    attrs = task_update_params.except(:return_to)
    attrs.keys.map(&:to_s) == [ "status" ] && attrs[:status].to_s == Task.statuses[:completed]
  end

  def complete_task!
    if @task.completed?
      flash[:alert] = "Could not complete task."
      redirect_to safe_return_path, inertia: {
        errors: { status: [ "task is already completed" ] }
      }
      return
    end

    if @task.update(status: :completed)
      flash[:notice] = "Task completed."
      redirect_to safe_return_path
    else
      flash[:alert] = "Could not complete task."
      redirect_to safe_return_path, inertia: { errors: validation_errors(@task) }
    end
  end

  def update_task_fields!
    attrs = task_field_attributes
    requested_status = attrs[:status].to_s.presence
    reopening = status_leaving_completed?(requested_status)
    completing = requested_status == Task.statuses[:completed] && !@task.completed?

    if reopening && !policy(@task).revert?
      flash[:alert] = "You are not authorized to reopen this task."
      redirect_to safe_return_path
      return
    end

    editable_statuses = Task.statuses.values - [ Task.statuses[:overdue] ]
    if requested_status.present? && editable_statuses.exclude?(requested_status)
      flash[:alert] = "Could not update task."
      redirect_to safe_return_path, inertia: {
        errors: { status: [ "is invalid" ] }
      }
      return
    end

    apply_assignee_on_update!(attrs)

    if @task.update(attrs)
      flash[:notice] = if reopening
        "Task reopened."
      elsif completing
        "Task completed."
      else
        "Task updated."
      end
      redirect_to safe_return_path
    else
      flash[:alert] = "Could not update task."
      redirect_to safe_return_path, inertia: { errors: validation_errors(@task) }
    end
  end

  def task_field_attributes
    raw = params.permit(:title, :description, :due_date, :status, :user_id)
    attrs = {}
    attrs[:title] = raw[:title] if raw.key?(:title)
    attrs[:description] = raw[:description] if raw.key?(:description)
    attrs[:due_date] = raw[:due_date] if raw.key?(:due_date)
    attrs[:status] = raw[:status] if raw.key?(:status)
    attrs[:user_id] = raw[:user_id] if raw.key?(:user_id)
    attrs
  end

  def status_leaving_completed?(requested_status)
    @task.completed? && requested_status.present? && requested_status != Task.statuses[:completed]
  end

  def apply_assignee_on_update!(attrs)
    if current_user.advisor?
      attrs.delete(:user_id)
      return
    end

    requested = Integer(attrs[:user_id], exception: false)
    if requested && assignable_user_ids.include?(requested)
      attrs[:user_id] = requested
    else
      attrs.delete(:user_id)
    end
  end

  def can_create_tasks?
    return true if current_user.admin? || current_user.assistant?

    current_user.advisor? && policy_scope(Lead).exists?
  end

  def form_options
    {
      leads: policy_scope(Lead).order(:name).map { |lead| { id: lead.id, name: lead.name } },
      assignees: assignees_for_form,
      defaults: {
        user_id: default_assignee_id,
        force_assignee: !current_user.admin? && !current_user.assistant?
      }
    }
  end

  def assignees_for_form
    return [ { id: current_user.id, name: current_user.name } ] if current_user.advisor?

    assignable_users.map { |user| { id: user.id, name: user.name } }
  end

  def assignable_users
    User.joins(:role)
      .where(roles: { name: %w[admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def assignable_user_ids
    @assignable_user_ids ||= assignable_users.pluck(:id)
  end

  def assigned_user_id(lead)
    return current_user.id if current_user.advisor?

    requested = Integer(task_create_params[:user_id], exception: false)
    return requested if requested && assignable_user_ids.include?(requested)

    return lead.user_id if lead.user_id && assignable_user_ids.include?(lead.user_id)

    assignable_user_ids.first
  end

  def default_assignee_id
    return current_user.id if current_user.advisor?

    assignable_user_ids.first
  end

  def task_create_params
    params.permit(:title, :due_date, :lead_id, :user_id, :return_to)
  end

  def task_update_params
    params.permit(:title, :description, :due_date, :status, :user_id, :return_to)
  end

  def validation_errors(task)
    task.errors.to_hash.transform_values { |messages| Array(messages) }
  end

  def lead_missing_errors
    if task_create_params[:lead_id].blank?
      { lead_id: [ "can't be blank" ] }
    else
      { lead_id: [ "is invalid or inaccessible" ] }
    end
  end

  def tasks_return_path(filter = "all", page = 1)
    opts = {}
    opts[:filter] = filter if filter.present? && filter != "all"
    opts[:page] = page if page.present? && page.to_i > 1
    tasks_path(opts)
  end

  def safe_return_path
    raw = (params[:return_to].presence || task_create_params[:return_to].presence || task_update_params[:return_to]).to_s
    return tasks_path if raw.blank?

    uri = URI.parse(raw)
    return tasks_path if uri.scheme.present? || uri.host.present?

    case uri.path
    when tasks_path, "/tasks"
      query = Rack::Utils.parse_nested_query(uri.query.to_s)
      filter = Array(query["filter"]).first.to_s
      page = Integer(Array(query["page"]).first, exception: false)
      tasks_return_path(FILTERS.include?(filter) ? filter : "all", page || 1)
    else
      match = uri.path.to_s.match(%r{\A/leads/(\d+)\z})
      if match
        lead = policy_scope(Lead).find_by(id: match[1])
        return lead_path(lead) if lead
      end

      tasks_path
    end
  rescue URI::InvalidURIError
    tasks_path
  end
end
