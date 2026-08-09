# frozen_string_literal: true

module Admin
  class UsersController < InertiaController
    PER_PAGE = 25

    before_action :set_user, only: %i[edit update]

    def index
      authorize User

      page = Integer(Array(params[:page]).first, exception: false) || 1
      page = [ page, 1 ].max

      scoped = policy_scope(User).includes(:role, :team, :country).order(:name, :id)
      total_count = scoped.count
      total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
      page = page.clamp(1, total_pages)

      users = scoped.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

      render inertia: "admin/users/index", props: {
        users: users.map { |user| serialize_user(user) },
        meta: {
          page: page,
          per_page: PER_PAGE,
          total_count: total_count,
          total_pages: total_pages
        },
        can_create: policy(User).create?
      }
    end

    def new
      authorize User

      render inertia: "admin/users/new", props: form_props(User.new(status: "active"))
    end

    def create
      authorize User

      if unauthorized_role_assignment?(user_attributes)
        flash[:alert] = "Only a billing admin can grant the admin or billing admin role."
        redirect_to new_admin_user_path
        return
      end

      user = User.new(user_attributes)
      user.password = password_param if password_param.present?

      if user.save
        flash[:notice] = "User created."
        redirect_to admin_users_path
      else
        redirect_to new_admin_user_path, inertia: { errors: user.errors.to_hash(true) }
      end
    end

    def edit
      authorize @user

      render inertia: "admin/users/edit", props: form_props(@user)
    end

    def update
      authorize @user

      attrs = user_attributes

      if status_to_disabled?(attrs) && !policy(@user).disable?
        flash[:alert] = "You cannot disable your own account."
        redirect_to edit_admin_user_path(@user)
        return
      end

      if demoting_self?(attrs)
        flash[:alert] = "You cannot change your own admin role."
        redirect_to edit_admin_user_path(@user)
        return
      end

      if unauthorized_role_assignment?(attrs)
        flash[:alert] = "Only a billing admin can grant the admin or billing admin role."
        redirect_to edit_admin_user_path(@user)
        return
      end

      if would_leave_zero_active_billing_admins?(attrs)
        flash[:alert] = "Cannot remove the last active billing administrator."
        redirect_to edit_admin_user_path(@user)
        return
      end

      if would_leave_zero_active_admins?(attrs)
        flash[:alert] = "Cannot remove the last active administrator."
        redirect_to edit_admin_user_path(@user)
        return
      end

      @user.assign_attributes(attrs)
      @user.password = password_param if password_param.present?

      if @user.save
        flash[:notice] = "User updated."
        redirect_to admin_users_path
      else
        redirect_to edit_admin_user_path(@user), inertia: { errors: @user.errors.to_hash(true) }
      end
    end

    private

    def set_user
      @user = policy_scope(User).includes(:role, :team, :country).find(params[:id])
    end

    def user_params
      params.permit(:name, :email, :role_id, :team_id, :country_id, :status, :password)
    end

    def password_param
      user_params[:password].to_s
    end

    def user_attributes
      user_params.except(:password).to_h
    end

    def attr_value(attrs, key)
      attrs[key.to_s] || attrs[key.to_sym]
    end

    def status_to_disabled?(attrs)
      attr_value(attrs, :status).to_s == "disabled"
    end

    def demoting_self?(attrs)
      return false unless @user == current_user && current_user.admin?

      new_role_id = attr_value(attrs, :role_id)
      return false if new_role_id.blank?

      new_role = Role.find_by(id: new_role_id)
      return false if new_role.blank?

      # Billing admins and admins cannot demote themselves.
      new_role.name != current_user.role.name
    end

    def unauthorized_role_assignment?(attrs)
      new_role_id = attr_value(attrs, :role_id)
      return false if new_role_id.blank?

      new_role = Role.find_by(id: new_role_id)
      return false if new_role.blank?
      return false if assignable_role_names.include?(new_role.name)

      true
    end

    def would_leave_zero_active_billing_admins?(attrs)
      return false unless @user.billing_admin? && @user.active?

      new_status = attr_value(attrs, :status)
      new_status = @user.status if new_status.nil?
      new_role_id = attr_value(attrs, :role_id) || @user.role_id
      new_role = Role.find_by(id: new_role_id)
      still_active = new_status.to_s != "disabled" && new_role&.name == "billing_admin"
      return false if still_active

      !User.billing_admins.where.not(id: @user.id).where.not(status: "disabled").exists?
    end

    def would_leave_zero_active_admins?(attrs)
      return false unless @user.admin? && @user.active?

      new_status = attr_value(attrs, :status)
      new_status = @user.status if new_status.nil?
      new_role_id = attr_value(attrs, :role_id) || @user.role_id
      new_role = Role.find_by(id: new_role_id)
      still_active_admin = new_status.to_s != "disabled" && new_role&.name.in?(User::ADMIN_ROLE_NAMES)
      return false if still_active_admin

      !other_active_admins_exist?
    end

    def other_active_admins_exist?
      User.admins
        .where.not(id: @user.id)
        .where.not(status: "disabled")
        .exists?
    end

    def assignable_role_names
      if current_user.billing_admin?
        %w[billing_admin admin advisor assistant]
      else
        %w[advisor assistant]
      end
    end

    def form_props(user)
      {
        user: serialize_user_form(user),
        roles: Role.where(name: assignable_role_names).order(:name).map { |role| { id: role.id, name: role.name } },
        teams: Team.order(:name).map { |team| { id: team.id, name: team.name } },
        countries: Country.order(:name).map { |country| { id: country.id, name: country.name } },
        can_disable: user.persisted? ? policy(user).disable? : true,
        can_edit_role: can_edit_role?(user)
      }
    end

    def can_edit_role?(user)
      return true unless user.persisted?
      return false if user == current_user && user.admin?
      return true if current_user.billing_admin?

      # Regular admins can demote other admins / manage advisors, but not billing admins.
      !user.billing_admin?
    end

    def serialize_user(user)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
        status: user.status.presence || "active",
        team: user.team.name,
        can_update: policy(user).update?
      }
    end

    def serialize_user_form(user)
      {
        id: user.id,
        name: user.name.to_s,
        email: user.email.to_s,
        role_id: user.role_id,
        team_id: user.team_id,
        country_id: user.country_id,
        status: user.status.presence || "active"
      }
    end
  end
end
