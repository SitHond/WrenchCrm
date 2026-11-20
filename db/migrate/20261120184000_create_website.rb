class CreateWebsite < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.boolean :enabled, null: false, default: true
      t.string :title
      t.string :tagline
      t.text :about
      t.text :schedule
      t.string :telegram
      t.string :whatsapp
      t.string :vk
      t.string :theme, null: false, default: "orange"
      t.boolean :booking_enabled, null: false, default: true
      t.text :booking_success_text
      t.string :seo_title
      t.string :seo_description
      t.string :metrika_id
      t.timestamps
    end

    create_table :site_banners do |t|
      t.string :title, null: false
      t.text :text
      t.string :button_text
      t.string :button_url
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.date :starts_on
      t.date :ends_on
      t.timestamps
    end

    create_table :site_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body
      t.boolean :published, null: false, default: true
      t.boolean :show_in_menu, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :site_pages, :slug, unique: true

    create_table :site_promotions do |t|
      t.string :title, null: false
      t.text :text
      t.boolean :active, null: false, default: true
      t.date :starts_on
      t.date :ends_on
      t.timestamps
    end

    create_table :site_reviews do |t|
      t.string :author, null: false
      t.text :text, null: false
      t.integer :rating, null: false, default: 5
      t.date :reviewed_on
      t.boolean :published, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    change_table :services, bulk: true do |t|
      t.boolean :show_on_site, null: false, default: false
      t.text :site_description
    end
    change_table :leads, bulk: true do |t|
      t.datetime :personal_data_consent_at
      t.string :personal_data_consent_ip
    end
    add_column :users, :manage_site, :boolean, null: false, default: false
  end
end
