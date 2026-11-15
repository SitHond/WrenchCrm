# Keys for encrypted attributes (two-factor secrets) derived from SECRET_KEY_BASE,
# so deployments need no extra secrets. Changing SECRET_KEY_BASE makes users set up two-factor sign-in again.
Rails.application.config.after_initialize do
  generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000)
  ActiveRecord::Encryption.configure(
    primary_key: generator.generate_key("active record encryption primary key", 32).unpack1("H*"),
    deterministic_key: generator.generate_key("active record encryption deterministic key", 32).unpack1("H*"),
    key_derivation_salt: generator.generate_key("active record encryption salt", 32).unpack1("H*")
  )
end
