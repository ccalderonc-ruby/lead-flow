# frozen_string_literal: true

class TasksController < InertiaController
  PER_PAGE = 25
  FILTERS = %w[all mine overdue].freeze
  COMPLETED = "completed"
  PENDING = "pending"

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
      redirect_to safe_return_path, inertia: { errors: lead_missing_errors }
      return
    end

    task = Task.new(lead: lead)
    authorize task

    task.assign_attributes(
      title: task_create_params[:title],
      due_date: task_create_params[:due_date],
      user_id: assigned_user_id(lead),
      status: PENDING
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

    requested = task_update_params[:status].to_s
    unless requested == COMPLETED
      flash[:alert] = "Could not complete task."
      redirect_to safe_return_path, inertia: {
        errors: { status: [ "can only be set to completed" ] }
      }
      return
    end

    unless @task.status == PENDING
      flash[:alert] = "Could not complete task."
      redirect_to safe_return_path, inertia: {
        errors: { status: [ "can only complete pending tasks" ] }
      }
      return
    end

    if @task.update(status: COMPLETED)
      flash[:notice] = "Task completed."
      redirect_to safe_return_path
    else
      flash[:alert] = "Could not complete task."
      redirect_to safe_return_path, inertia: { errors: validation_errors(@task) }
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
    when "overdue"
      scoped.where(status: "pending").where(due_date: ...Date.current)
    else
      scoped
    end
  end

  def serialize_task(task)
    {
      id: task.id,
      title: task.title,
      lead: task.lead&.name,
      lead_id: task.lead_id,
      due_date: task.due_date&.iso8601,
      status: task.status,
      assignee: task.user&.name,
      can_complete: can_complete?(task)
    }
  end

  def can_complete?(task)
    task.status == PENDING && policy(task).update?
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
    params.permit(:status, :return_to)
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
