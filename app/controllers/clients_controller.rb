class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy ]
  require_permission :manage_clients, only: %i[ new create edit update ]
  require_permission :delete_records, only: :destroy

  def index
    scope = Client.search(params[:q])
    scope = params[:status] == "inactive" ? scope.inactive : scope.active
    @pagy, @clients = pagy(scope.ordered.includes(:vehicles), limit: 25)
  end

  def show
    @work_orders = @client.work_orders.includes(:vehicle).limit(20)
    @notes = @client.notes.visible_to(current_user).recent_first.includes(:author)
  end

  def new
    @client = Client.new(kind: params[:kind].presence_in(Client.kinds.keys) || "individual")
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to params[:with_vehicle] ? new_vehicle_path(client_id: @client.id) : @client,
                  notice: t("flash.created", model: Client.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: t("flash.updated", model: Client.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: t("flash.destroyed", model: Client.model_name.human), status: :see_other
    else
      redirect_to @client, alert: @client.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.expect(client: [
        :kind, :last_name, :first_name, :middle_name, :company_name, :inn, :phone, :phone2,
        :email, :address, :discount_percent, :deactivated_on
      ])
    end
end
