class ComplexityLevelsController < ApplicationController
  require_permission :admin

  def create
    level = ComplexityLevel.new(params.expect(complexity_level: [ :name ]))
    level.position = ComplexityLevel.maximum(:position).to_i + 1
    if level.save
      redirect_to edit_shop_settings_path(anchor: "complexity")
    else
      redirect_to edit_shop_settings_path(anchor: "complexity"), alert: level.errors.full_messages.to_sentence
    end
  end

  def destroy
    ComplexityLevel.find(params[:id]).destroy
    redirect_to edit_shop_settings_path(anchor: "complexity"), status: :see_other
  end
end
