module Site
  # Online booking form: creates a lead in the CRM pipeline.
  class BookingsController < BaseController
    rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to site_new_booking_path, alert: t("site.booking.rate_limited") }
    before_action :require_booking

    def new
      @booking = Booking.new
    end

    def create
      @booking = Booking.new(booking_params)
      # Bots fill every field, people never see this one.
      return redirect_to(site_new_booking_path(sent: 1)) if params[:website].present?

      if @booking.valid?
        @booking.to_lead!(ip: request.remote_ip)
        redirect_to site_new_booking_path(sent: 1)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def require_booking
        redirect_to site_root_path unless site.booking_enabled?
      end

      def booking_params
        params.expect(booking: [ :name, :phone, :vehicle, :request, :preferred_time, :consent ])
      end
  end
end
