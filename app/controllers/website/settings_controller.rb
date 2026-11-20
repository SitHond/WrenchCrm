module Website
  class SettingsController < ApplicationController
    require_permission :manage_site

    def edit
      @site = SiteSetting.current
    end

    def update
      @site = SiteSetting.current
      @site.logo.purge if params[:remove_logo] == "1"
      if @site.update(site_params)
        redirect_to edit_website_settings_path, notice: t("flash.updated", model: t("website.title"))
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def site_params
        params.expect(site_setting: [ :enabled, :title, :tagline, :about, :schedule, :telegram, :whatsapp, :vk, :theme,
                                      :booking_enabled, :booking_success_text, :seo_title, :seo_description, :metrika_id, :logo ])
      end
  end
end
