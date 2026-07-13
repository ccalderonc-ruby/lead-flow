# frozen_string_literal: true

class LeadsController < InertiaController
  PER_PAGE = 25
  MAX_QUERY_LENGTH = 100

  def index
    authorize Lead

    query = Array(params[:q]).first.to_s.strip.slice(0, MAX_QUERY_LENGTH)
    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    scoped = policy_scope(Lead).search(query)
    total_count = scoped.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    leads = scoped
      .includes(:company, :stage, :user)
      .order(Arel.sql("COALESCE(leads.last_activity_at, leads.updated_at) DESC"))
      .offset((page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    render inertia: "leads/index", props: {
      leads: leads.map { |lead| serialize_lead(lead) },
      meta: {
        q: query,
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end

  private

  def serialize_lead(lead)
    {
      id: lead.id,
      name: lead.name,
      email: lead.email,
      company: lead.company&.name,
      stage: lead.stage&.name,
      advisor: lead.user&.name,
      last_activity_at: (lead.last_activity_at || lead.updated_at)&.iso8601,
      estimated_value: lead.estimated_value&.to_s
    }
  end
end
