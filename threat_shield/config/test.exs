import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :threat_shield, ThreatShield.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "threat_shield_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :threat_shield, ThreatShieldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "C6I3EPa0nUeEzFNMSSZuZEM4HmNR3WPgl8uSk3MGKshPr4qbovbqyWEm4q05+i3c",
  server: false

# In test we don't send emails.
config :threat_shield, ThreatShield.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
