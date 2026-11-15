class LeadsController < ApplicationController
  before_action :set_lead, only: %i[ show edit update destroy move ]
  require_permission :manage_clients, except: %i[ index show board ]

  def index
    scope = Lead.includes(:client, :assignee, :ad_source).recent_first
    scope = params[:status].presence_in(Lead.statuses.keys) ? scope.where(status: params[:status]) : scope.open
    scope = scope.where("leads.name ILIKE :q OR leads.phone ILIKE :q OR leads.request ILIKE :q", q: "%#{Lead.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @pagy, @leads = pagy(scope, limit: 30)
  end

  def board
    @columns = Lead.statuses.keys.index_with do |status|
      scope = Lead.where(status: status).includes(:client, :assignee)
      status.in?(%w[won lost]) ? scope.where(updated_at: 30.days.ago..).order(updated_at: :desc).limit(30) : scope.order(:next_contact_on, :created_at)
    end
  end

  def show
    audit(:view, @lead)
    @notes = @lead.notes.visible_to(current_user).recent_first.includes(:author)
  end

  def new
    @lead = Lead.new(channel: :call, next_contact_on: Date.current, phone: params[:phone])
  end

  def create
    @lead = Lead.new(lead_params)
    if @lead.save
      redirect_to @lead, notice: @lead.client ? t("leads.created_with_client", client: @lead.client.display_name) : t("flash.created", model: Lead.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lead.update(lead_params)
      redirect_to @lead, notice: t("flash.updated", model: Lead.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Status change from the board or the lead page.
  def move
    status = params.expect(:status)
    if status == "lost" && params[:lost_reason].blank? && @lead.lost_reason.blank?
      redirect_to edit_lead_path(@lead, lost: 1), alert: t("leads.lost_reason_needed")
    elsif Lead.statuses.key?(status) && @lead.update(status: status, lost_reason: params[:lost_reason].presence || @lead.lost_reason)
      redirect_back fallback_location: board_leads_path, notice: t("leads.moved", status: helpers.enum_label(Lead, :status, status)), status: :see_other
    else
      redirect_back fallback_location: board_leads_path, alert: @lead.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    require_permission(:delete_records)
    return if performed?

    @lead.destroy
    redirect_to leads_path, notice: t("flash.destroyed", model: Lead.model_name.human), status: :see_other
  end

  private
    def set_lead
      @lead = Lead.find(params[:id])
    end

    def lead_params
      params.expect(lead: [ :name, :phone, :vehicle_info, :request, :channel, :ad_source_id, :status, :lost_reason,
                            :assignee_id, :next_contact_on, :client_id ])
    end
end
