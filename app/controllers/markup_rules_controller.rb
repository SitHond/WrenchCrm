class MarkupRulesController < ApplicationController
  require_permission :manage_catalog

  def create
    rule = MarkupRule.new(params.expect(markup_rule: [ :cost_from, :percent ]))
    if rule.save
      redirect_to edit_shop_settings_path(anchor: "markup")
    else
      redirect_to edit_shop_settings_path(anchor: "markup"), alert: rule.errors.full_messages.to_sentence
    end
  end

  def destroy
    MarkupRule.find(params[:id]).destroy
    redirect_to edit_shop_settings_path(anchor: "markup"), status: :see_other
  end
end
