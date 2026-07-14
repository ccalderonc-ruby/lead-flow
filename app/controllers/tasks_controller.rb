# frozen_string_literal: true

class TasksController < InertiaController
  PER_PAGE = 25
  FILTERS = %w[all mine overdue].freeze

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
      }
    }
  end

  private

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
      assignee: task.user&.name
    }
  end
end
