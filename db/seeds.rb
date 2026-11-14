# Idempotent: safe to run on every container start.
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
unless User.exists?(admin: true)
  User.create!(
    name: "Administrator",
    email_address: admin_email,
    password: ENV.fetch("ADMIN_PASSWORD", "changeme123"),
    admin: true
  )
  puts "Created admin user #{admin_email}"
end

load Rails.root.join("db/seeds/demo.rb") if Rails.env.development? || ENV["SEED_DEMO"] == "1"
