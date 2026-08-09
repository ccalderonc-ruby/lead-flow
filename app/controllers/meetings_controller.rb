# frozen_string_literal: true

class MeetingsController < InertiaController
  PER_PAGE = 25
  EDITABLE_STATUSES = Meeting.statuses.values.freeze

  before_action :set_meeting, only: :update

  def index
    authorize Meeting

    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    scoped = policy_scope(Meeting)
    total_count = scoped.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    meetings = scoped
      .includes(:lead, :user)
      .order(:scheduled_on, :start_time, :id)
      .offset((page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    render inertia: "meetings/index", props: {
      meetings: meetings.map { |meeting| serialize_meeting(meeting) },
      meta: {
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        total_pages: total_pages
      },
      **form_options,
      can_create: can_create_meetings?,
      return_to: meetings_return_path(page)
    }
  end

  def create
    lead = policy_scope(Lead).find_by(id: meeting_create_params[:lead_id])
    unless lead
      skip_authorization
      redirect_to safe_return_path, inertia: { errors: lead_missing_errors.merge(form: [ "meeting" ]) }
      return
    end

    meeting = Meeting.new(lead: lead)
    authorize meeting

    meeting.assign_attributes(
      title: meeting_create_params[:title],
      scheduled_on: meeting_create_params[:scheduled_on],
      start_time: meeting_create_params[:start_time],
      location: meeting_create_params[:location],
      virtual_link: meeting_create_params[:virtual_link],
      virtual_meeting: virtual_meeting_flag(meeting_create_params),
      user_id: assigned_user_id(lead, meeting_create_params[:user_id]),
      status: :scheduled
    )

    if meeting.save
      flash[:notice] = "Meeting scheduled."
      redirect_to safe_return_path
    else
      redirect_to safe_return_path, inertia: { errors: validation_errors(meeting) }
    end
  end

  def update
    authorize @meeting
    update_meeting_fields!
  end

  private

  def set_meeting
    @meeting = policy_scope(Meeting).includes(:lead).find(params[:id])
  end

  def serialize_meeting(meeting)
    {
      id: meeting.id,
      title: meeting.title,
      lead: meeting.lead&.name,
      lead_id: meeting.lead_id,
      scheduled_on: meeting.scheduled_on&.iso8601,
      start_time: format_start_time(meeting.start_time),
      location: meeting.location,
      virtual_link: meeting.virtual_link,
      virtual_meeting: meeting.virtual_meeting,
      status: meeting.status,
      host: meeting.user&.name,
      user_id: meeting.user_id,
      can_edit: policy(meeting).update?,
      can_revert: can_revert?(meeting)
    }
  end

  def format_start_time(value)
    return if value.blank?

    value.strftime("%H:%M")
  end

  def can_revert?(meeting)
    terminal_status?(meeting.status) && policy(meeting).revert?
  end

  def terminal_status?(status)
    status.to_s.in?([ Meeting.statuses[:completed], Meeting.statuses[:cancelled] ])
  end

  def update_meeting_fields!
    attrs = meeting_field_attributes
    requested_status = attrs[:status].to_s.presence
    reopening = status_leaving_terminal?(requested_status)
    completing = requested_status == Meeting.statuses[:completed] && !@meeting.completed?

    if reopening && !policy(@meeting).revert?
      flash[:alert] = "You are not authorized to reopen this meeting."
      redirect_to safe_return_path
      return
    end

    if requested_status.present? && EDITABLE_STATUSES.exclude?(requested_status)
      flash[:alert] = "Could not update meeting."
      redirect_to safe_return_path, inertia: {
        errors: { status: [ "is invalid" ], form: [ "meeting" ] }
      }
      return
    end

    apply_host_on_update!(attrs)
    attrs[:virtual_meeting] = virtual_meeting_flag(attrs) if attrs.key?(:virtual_link) || attrs.key?(:virtual_meeting)

    if @meeting.update(attrs)
      flash[:notice] = if reopening
        "Meeting reopened."
      elsif completing
        "Meeting completed."
      else
        "Meeting updated."
      end
      redirect_to safe_return_path
    else
      flash[:alert] = "Could not update meeting."
      redirect_to safe_return_path, inertia: { errors: validation_errors(@meeting) }
    end
  end

  def meeting_field_attributes
    raw = params.permit(
      :title,
      :scheduled_on,
      :start_time,
      :location,
      :virtual_link,
      :virtual_meeting,
      :status,
      :user_id
    )
    attrs = {}
    attrs[:title] = raw[:title] if raw.key?(:title)
    attrs[:scheduled_on] = raw[:scheduled_on] if raw.key?(:scheduled_on)
    attrs[:start_time] = raw[:start_time] if raw.key?(:start_time)
    attrs[:location] = raw[:location] if raw.key?(:location)
    attrs[:virtual_link] = raw[:virtual_link] if raw.key?(:virtual_link)
    attrs[:virtual_meeting] = raw[:virtual_meeting] if raw.key?(:virtual_meeting)
    attrs[:status] = raw[:status] if raw.key?(:status)
    attrs[:user_id] = raw[:user_id] if raw.key?(:user_id)
    attrs
  end

  def status_leaving_terminal?(requested_status)
    terminal_status?(@meeting.status) &&
      requested_status.present? &&
      !terminal_status?(requested_status)
  end

  def apply_host_on_update!(attrs)
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

  def can_create_meetings?
    return true if current_user.admin?
    return false if current_user.assistant?

    current_user.advisor? && policy_scope(Lead).exists?
  end

  def form_options
    {
      leads: policy_scope(Lead).order(:name).map { |lead| { id: lead.id, name: lead.name } },
      hosts: hosts_for_form,
      defaults: {
        user_id: default_host_id,
        force_host: !current_user.admin?
      }
    }
  end

  def hosts_for_form
    return [ { id: current_user.id, name: current_user.name } ] if current_user.advisor?

    assignable_users.map { |user| { id: user.id, name: user.name } }
  end

  def assignable_users
    User.joins(:role)
      .where(roles: { name: %w[billing_admin admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def assignable_user_ids
    @assignable_user_ids ||= assignable_users.pluck(:id)
  end

  def assigned_user_id(lead, requested_user_id = nil)
    return current_user.id if current_user.advisor?

    requested = Integer(requested_user_id, exception: false)
    return requested if requested && assignable_user_ids.include?(requested)

    return lead.user_id if lead.user_id && assignable_user_ids.include?(lead.user_id)

    assignable_user_ids.first
  end

  def default_host_id
    return current_user.id if current_user.advisor?

    assignable_user_ids.first
  end

  def virtual_meeting_flag(source)
    flag = ActiveModel::Type::Boolean.new.cast(source[:virtual_meeting])
    return true if flag
    return true if source[:virtual_link].to_s.strip.present?

    false
  end

  def meeting_create_params
    params.permit(
      :title,
      :scheduled_on,
      :start_time,
      :lead_id,
      :user_id,
      :location,
      :virtual_link,
      :virtual_meeting,
      :return_to
    )
  end

  def meeting_update_params
    params.permit(
      :title,
      :scheduled_on,
      :start_time,
      :location,
      :virtual_link,
      :virtual_meeting,
      :status,
      :user_id,
      :return_to
    )
  end

  def validation_errors(meeting)
    meeting.errors.to_hash.transform_values { |messages| Array(messages) }.merge(form: [ "meeting" ])
  end

  def lead_missing_errors
    if meeting_create_params[:lead_id].blank?
      { lead_id: [ "can't be blank" ] }
    else
      { lead_id: [ "is invalid or inaccessible" ] }
    end
  end

  def meetings_return_path(page = 1)
    opts = {}
    opts[:page] = page if page.present? && page.to_i > 1
    meetings_path(opts)
  end

  def safe_return_path
    raw = (
      params[:return_to].presence ||
      meeting_create_params[:return_to].presence ||
      meeting_update_params[:return_to]
    ).to_s
    return meetings_path if raw.blank?

    uri = URI.parse(raw)
    return meetings_path if uri.scheme.present? || uri.host.present?

    case uri.path
    when root_path, "/"
      root_path
    when meetings_path, "/meetings"
      query = Rack::Utils.parse_nested_query(uri.query.to_s)
      page = Integer(Array(query["page"]).first, exception: false)
      meetings_return_path(page || 1)
    else
      match = uri.path.to_s.match(%r{\A/leads/(\d+)\z})
      if match
        lead = policy_scope(Lead).find_by(id: match[1])
        return lead_path(lead) if lead
      end

      meetings_path
    end
  rescue URI::InvalidURIError
    meetings_path
  end
end
