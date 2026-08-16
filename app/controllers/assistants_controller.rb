# frozen_string_literal: true

class AssistantsController < InertiaController
  def index
    authorize AdvisorAssistant

    advisor = managed_advisor
    unless advisor
      redirect_to root_path, alert: "You are not authorized to manage assistants."
      return
    end

    assignments_scope = AdvisorAssistant
      .includes(:assistant)
      .where(advisor_id: advisor.id)
      .joins(:assistant)
      .merge(User.order(:name, :id))

    total_count = assignments_scope.count
    pagination = resolve_pagination(total_count)
    assignments = apply_pagination(assignments_scope, pagination)

    available = User.assistants
      .on_team(advisor.team)
      .where.not(id: assignments_scope.select(:assistant_id))
      .where.not(status: "disabled")
      .order(:name, :id)

    render inertia: "assistants/index", props: {
      advisor: { id: advisor.id, name: advisor.name },
      assignments: assignments.map { |row| serialize_assignment(row) },
      available_assistants: available.map { |user| serialize_user(user) },
      meta: pagination,
      can_manage: can_manage_for?(advisor),
      managed_advisors: managed_advisor_options
    }
  end

  def create
    advisor = managed_advisor
    unless advisor
      skip_authorization
      redirect_to root_path, alert: "You are not authorized to manage assistants."
      return
    end

    assistant = User.assistants.on_team(advisor.team).find_by(id: assignment_params[:assistant_id])
    if assistant.nil?
      skip_authorization
      redirect_to assistants_path(advisor_id: advisor.id), alert: "Select a valid assistant."
      return
    end

    assignment = AdvisorAssistant.new(advisor: advisor, assistant: assistant)
    authorize assignment

    if assignment.save
      redirect_to assistants_path(advisor_id: advisor.id), notice: "#{assistant.name} can now access your records."
    else
      redirect_to assistants_path(advisor_id: advisor.id),
        alert: assignment.errors.full_messages.to_sentence.presence || "Could not assign assistant."
    end
  end

  def destroy
    assignment = AdvisorAssistant.find(params[:id])
    authorize assignment

    advisor_id = assignment.advisor_id
    name = assignment.assistant.name
    assignment.destroy!

    redirect_to assistants_path(advisor_id: advisor_id), notice: "#{name} no longer has access to those records."
  end

  private

  def assignment_params
    params.permit(:assistant_id, :advisor_id)
  end

  def managed_advisor
    if current_user.advisor?
      current_user
    elsif current_user.admin?
      id = Integer(Array(params[:advisor_id]).first, exception: false)
      id ||= Integer(Array(assignment_params[:advisor_id]).first, exception: false)
      User.advisors.on_team(current_user.team).find_by(id: id) || User.advisors.on_team(current_user.team).order(:name).first
    end
  end

  def can_manage_for?(advisor)
    return true if current_user.admin?
    current_user.advisor? && current_user.id == advisor.id
  end

  def managed_advisor_options
    return [] unless current_user.admin?

    User.advisors.on_team(current_user.team).order(:name, :id).map { |user| serialize_user(user) }
  end

  def serialize_assignment(row)
    {
      id: row.id,
      assistant: serialize_user(row.assistant)
    }
  end

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end
