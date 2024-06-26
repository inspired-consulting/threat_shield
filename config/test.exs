import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :threat_shield, ThreatShield.Repo,
  username: System.get_env("POSTGRES_USER", "threat_shield"),
  password: System.get_env("POSTGRES_PASSWORD", "secret"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "threat_shield_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :threat_shield, ThreatShieldWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  secret_key_base: "93/0t4jyvnG1LKoP16HFrzvyCMfH0Is24g1ceBQPXcBgJnNbhW4hztLF4ywc8bTl",
  server: false

# In test we don't send emails.
config :threat_shield, ThreatShield.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, :console, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
