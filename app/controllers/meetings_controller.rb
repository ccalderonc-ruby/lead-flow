# frozen_string_literal: true

class MeetingsController < InertiaController
  EDITABLE_STATUSES = Meeting.statuses.values.freeze

  before_action :set_meeting, only: :update

  def index
    authorize Meeting

    scoped = policy_scope(Meeting)
    total_count = scoped.count
    pagination = resolve_pagination(total_count)

    meetings = apply_pagination(
      scoped.includes(:lead, :user).order(:scheduled_on, :start_time, :id),
      pagination
    )

    render inertia: "meetings/index", props: {
      meetings: meetings.map { |meeting| serialize_meeting(meeting) },
      meta: pagination,
      **form_options,
      can_create: can_create_meetings?,
      return_to: meetings_return_path(pagination[:page], pagination[:per_page])
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
      video_provider: normalized_video_provider(meeting_create_params[:video_provider]),
      virtual_meeting: virtual_meeting_flag(meeting_create_params),
      user_id: assigned_user_id(lead, meeting_create_params[:user_id]),
      status: :scheduled
    )

    begin
      apply_generated_conference_link!(meeting, meeting_create_params)
    rescue Meetings::ConferenceError => e
      redirect_to safe_return_path, inertia: {
        errors: { base: [ e.message ], video_provider: [ e.message ], form: [ "meeting" ] }
      }
      return
    end

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
      video_provider: meeting.video_provider,
      external_meeting_id: meeting.external_meeting_id,
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

    @meeting.assign_attributes(attrs)

    begin
      apply_generated_conference_link!(@meeting, params)
    rescue Meetings::ConferenceError => e
      flash[:alert] = "Could not update meeting."
      redirect_to safe_return_path, inertia: {
        errors: { base: [ e.message ], video_provider: [ e.message ], form: [ "meeting" ] }
      }
      return
    end

    if @meeting.save
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
      :video_provider,
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
    attrs[:video_provider] = normalized_video_provider(raw[:video_provider]) if raw.key?(:video_provider)
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
    return true if generate_conference_link?(source) && normalized_video_provider(source[:video_provider]).present?

    false
  end

  def generate_conference_link?(source)
    ActiveModel::Type::Boolean.new.cast(source[:generate_conference_link])
  end

  def normalized_video_provider(value)
    value.to_s.strip.presence
  end

  def apply_generated_conference_link!(meeting, source)
    return unless generate_conference_link?(source)

    provider = normalized_video_provider(source[:video_provider]) || meeting.video_provider
    return if provider.blank?

    start_at = meeting.starts_at || Time.current
    result = Meetings::ConferenceLinkGenerator.call(
      provider: provider,
      title: meeting.title.to_s,
      start_at: start_at,
      duration_minutes: meeting.duration_minutes.presence || 30
    )

    meeting.video_provider = provider
    meeting.virtual_link = result.join_url
    meeting.external_meeting_id = result.external_id
    meeting.virtual_meeting = true
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
      :video_provider,
      :generate_conference_link,
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
      :video_provider,
      :generate_conference_link,
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

  def meetings_return_path(page = 1, per_page = DEFAULT_PER_PAGE)
    meetings_path(pagination_path_opts(page: page, per_page: per_page))
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
      page = Integer(Array(query["page"]).first, exception: false) || 1
      per_page = Integer(Array(query["per_page"]).first, exception: false) || DEFAULT_PER_PAGE
      per_page = DEFAULT_PER_PAGE unless ALLOWED_PER_PAGE.include?(per_page)
      meetings_return_path(page, per_page)
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
