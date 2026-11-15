class AddPrivacyPolicyToShopSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_settings, :privacy_policy_text, :text
  end
end
