class ShopSettingsController < ApplicationController
  require_permission :admin

  def edit
    @setting = ShopSetting.current
    @complexity_levels = ComplexityLevel.ordered
  end

  def update
    @setting = ShopSetting.current
    if @setting.update(setting_params)
      redirect_to edit_shop_settings_path, notice: t("flash.updated", model: t("shop_settings.title"))
    else
      @complexity_levels = ComplexityLevel.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def setting_params
      params.expect(shop_setting: [ :allow_negative_stock, :name, :legal_name, :inn, :kpp, :ogrn, :address, :phone, :email,
                                    :website, :bank_name, :bik, :bank_account, :correspondent_account, :director, :work_order_terms ])
    end
end
