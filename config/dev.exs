import Config

# Configure your database
config :threat_shield, ThreatShield.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER", "threat_shield"),
  password: System.get_env("POSTGRES_PASSWORD", "secret"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: System.get_env("POSTGRES_DB", "threat_shield"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.

host = System.get_env("PHX_HOST") || "localhost"

config :threat_shield, ThreatShieldWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  url: [host: host, port: 4000, scheme: "http"],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "ylXDwW4IvMTPYI1vpzcqBOthGcZodNm6DaFGbvt/iPSsGatDQaFk+iYwwX2/MG5q",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# OPENAI
config :openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/org-settings under "Organization ID"
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 30_000]

# Watch static and templates for browser reloading.
config :threat_shield, ThreatShieldWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/threat_shield_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :threat_shield, dev_routes: true

# For Dev just console logger without metadata nor timestamps
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
