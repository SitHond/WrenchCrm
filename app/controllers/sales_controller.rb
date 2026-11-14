class SalesController < ApplicationController
  before_action :set_sale, only: %i[ show destroy ]
  require_permission :manage_payments, except: %i[ index show ]

  def index
    @pagy, @sales = pagy(Sale.includes(:client, :lines, :cash_account).recent_first, limit: 25)
  end

  def show
  end

  def new
    @sale = Sale.new(client_id: params[:client_id])
    5.times { @sale.lines.build(quantity: 1) }
  end

  def create
    @sale = Sale.new(sale_params)
    if @sale.save
      redirect_to @sale, notice: t("sales.created")
    else
      (5 - @sale.lines.size).times { @sale.lines.build(quantity: 1) }
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    require_permission(:delete_records)
    return if performed?

    @sale.destroy
    redirect_to sales_path, notice: t("flash.destroyed", model: Sale.model_name.human), status: :see_other
  end

  private
    def set_sale
      @sale = Sale.find(params[:id])
    end

    def sale_params
      params.expect(sale: [ :client_id, :payment_method, :cash_account_id, :discount_percent, :comment,
                            lines_attributes: [ [ :part_id, :name, :quantity, :price ] ] ])
    end
end
