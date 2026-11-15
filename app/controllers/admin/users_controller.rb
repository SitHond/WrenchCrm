module Admin
  class UsersController < ApplicationController
    require_permission :admin
    before_action :set_user, only: %i[ edit update destroy reset_two_factor ]

    def index
      @users = User.ordered
    end

    def new
      @user = User.new(active: true, locale: I18n.locale)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        audit(:create, @user)
        redirect_to admin_users_path, notice: t("flash.created", model: User.model_name.human)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      attrs = attrs.except(:admin, :active) if @user == current_user

      if @user.update(attrs)
        audit(:user_update, @user, fields: audit_changes(@user) - %w[password_digest] + (@user.saved_change_to_password_digest? ? [ "password" ] : []))
        @user.sessions.where.not(id: Current.session.id).destroy_all if @user.saved_change_to_password_digest? || !@user.active?
        redirect_to admin_users_path, notice: t("flash.updated", model: User.model_name.human)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reset_two_factor
      @user.disable_two_factor!
      @user.sessions.destroy_all
      audit(:two_factor, @user, change: "reset by admin")
      redirect_to edit_admin_user_path(@user), notice: t("two_factor.reset_done")
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: t("admin.users.cannot_delete_self"), status: :see_other
      else
        @user.destroy
        redirect_to admin_users_path, notice: t("flash.destroyed", model: User.model_name.human), status: :see_other
      end
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.expect(user: [ :name, :email_address, :password, :password_confirmation, :locale,
                              :active, :admin, *User::PERMISSIONS ])
      end
  end
end
