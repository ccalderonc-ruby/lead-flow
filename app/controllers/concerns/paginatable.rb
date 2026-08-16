# frozen_string_literal: true

# Shared page/per_page parsing for Inertia list indexes.
module Paginatable
  extend ActiveSupport::Concern

  ALLOWED_PER_PAGE = [ 10, 25, 50, 100 ].freeze
  DEFAULT_PER_PAGE = 25

  private

  def resolve_pagination(total_count)
    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    per_page = Integer(Array(params[:per_page]).first, exception: false) || DEFAULT_PER_PAGE
    per_page = DEFAULT_PER_PAGE unless ALLOWED_PER_PAGE.include?(per_page)

    total_pages = [ (total_count.to_f / per_page).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    {
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  def apply_pagination(scope, meta)
    scope.offset((meta[:page] - 1) * meta[:per_page]).limit(meta[:per_page])
  end

  def pagination_path_opts(page:, per_page:)
    opts = {}
    opts[:page] = page if page.to_i > 1
    opts[:per_page] = per_page if per_page.to_i != DEFAULT_PER_PAGE
    opts
  end

  def pagination_redirect_params
    opts = {}
    page = Array(params[:page]).first.presence
    per_page = Array(params[:per_page]).first.presence
    opts[:page] = page if page
    opts[:per_page] = per_page if per_page
    opts
  end
end
