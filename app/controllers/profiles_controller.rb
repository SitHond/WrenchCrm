class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attrs = params.expect(user: [ :name, :locale, :password, :password_confirmation, :password_challenge ])
    attrs = attrs.except(:password, :password_confirmation, :password_challenge) if attrs[:password].blank?

    if @user.update(attrs)
      redirect_to edit_profile_path, notice: t("flash.updated", model: t("profiles.title"))
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
