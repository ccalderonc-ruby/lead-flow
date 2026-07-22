# frozen_string_literal: true

class MeetingsController < InertiaController
  PER_PAGE = 25

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
      virtual_meeting: virtual_meeting_flag,
      user_id: assigned_user_id(lead),
      status: :scheduled
    )

    if meeting.save
      flash[:notice] = "Meeting scheduled."
      redirect_to safe_return_path
    else
      redirect_to safe_return_path, inertia: { errors: validation_errors(meeting) }
    end
  end

  private

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
      host: meeting.user&.name
    }
  end

  def format_start_time(value)
    return if value.blank?

    value.strftime("%H:%M")
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
      .where(roles: { name: %w[admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def assignable_user_ids
    @assignable_user_ids ||= assignable_users.pluck(:id)
  end

  def assigned_user_id(lead)
    return current_user.id if current_user.advisor?

    requested = Integer(meeting_create_params[:user_id], exception: false)
    return requested if requested && assignable_user_ids.include?(requested)

    return lead.user_id if lead.user_id && assignable_user_ids.include?(lead.user_id)

    assignable_user_ids.first
  end

  def default_host_id
    return current_user.id if current_user.advisor?

    assignable_user_ids.first
  end

  def virtual_meeting_flag
    flag = ActiveModel::Type::Boolean.new.cast(meeting_create_params[:virtual_meeting])
    return true if flag
    return true if meeting_create_params[:virtual_link].to_s.strip.present?

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
    raw = (params[:return_to].presence || meeting_create_params[:return_to]).to_s
    return meetings_path if raw.blank?

    uri = URI.parse(raw)
    return meetings_path if uri.scheme.present? || uri.host.present?

    case uri.path
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
