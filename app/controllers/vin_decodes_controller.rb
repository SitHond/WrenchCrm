class VinDecodesController < ApplicationController
  def show
    decoder = VinDecoder.new(params[:vin])
    existing = Vehicle.includes(:client).find_by(vin: decoder.vin) if decoder.valid?
    existing = nil if existing && existing.id.to_s == params[:vehicle_id].to_s

    render json: decoder.to_h.merge(
      existing: existing && { label: existing.label, client: existing.client.display_name, url: vehicle_path(existing) }
    )
  end
end
