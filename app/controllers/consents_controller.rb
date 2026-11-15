class ConsentsController < ApplicationController
  require_permission :manage_clients, except: :print
  before_action :set_client

  def print
    @kind = params[:kind].presence_in(Consent.kinds.keys) || "personal_data"
    @shop = ShopSetting.current
    @text = Consent.text_for(@kind)
    audit(:print, @client, document: "consent_#{@kind}")
    render layout: "print"
  end

  def create
    consent = @client.consents.new(params.expect(consent: [ :kind, :channel ]))
    consent.text_version = Consent.version_for(consent.kind)
    consent.save!
    audit(:consent_given, @client, kind: consent.kind, channel: consent.channel, version: consent.text_version)
    redirect_to client_path(@client, anchor: "consents"), notice: t("consents.recorded")
  end

  def withdraw
    consent = @client.consents.active.find(params[:id])
    if params[:reason].blank?
      redirect_to client_path(@client, anchor: "consents"), alert: t("consents.reason_needed")
    else
      consent.withdraw!(params[:reason])
      audit(:consent_withdrawn, @client, kind: consent.kind, reason: params[:reason])
      redirect_to client_path(@client, anchor: "consents"), notice: t("consents.withdrawn")
    end
  end

  private
    def set_client
      @client = Client.find(params[:client_id])
    end
end
