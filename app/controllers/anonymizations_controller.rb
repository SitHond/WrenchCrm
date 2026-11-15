class AnonymizationsController < ApplicationController
  require_permission :delete_records

  def create
    client = Client.find(params[:client_id])
    if params[:reason].blank?
      redirect_to client, alert: t("privacy.reason_needed")
    else
      client.anonymize!(reason: params[:reason])
      redirect_to client, notice: t("privacy.anonymized")
    end
  end

  # Retention: anonymize everyone inactive longer than the configured number of years.
  def inactive
    require_permission(:admin)
    return if performed?

    years = ShopSetting.current.pd_retention_years
    return redirect_to(edit_shop_settings_path(anchor: "retention"), alert: t("privacy.retention_off")) unless years

    clients = ClientAnonymizer.inactive_clients(years).to_a
    clients.each { |client| client.anonymize!(reason: t("privacy.retention_reason", years: years)) }
    redirect_to edit_shop_settings_path(anchor: "retention"), notice: t("privacy.retention_done", count: clients.size)
  end
end
