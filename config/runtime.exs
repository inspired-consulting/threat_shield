import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/threat_shield start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :threat_shield, ThreatShieldWeb.Endpoint, server: true
end

if config_env() == :prod do
  cloud_sql_conn =
    System.get_env("CLOUD_SQL_CONNECTION_NAME") ||
      raise """
      environment variable CLOUD_SQL_CONNECTION_NAME is missing.
      """

  database_pw =
    System.get_env("DB_PASSWORD") ||
      raise """
      environment variable DB_PASSWORD is missing.
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :threat_shield, ThreatShield.Repo,
    # ssl: true,
    socket_dir: cloud_sql_conn,
    username: "threat_shield",
    password: database_pw,
    database: "threat_shield",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :threat_shield, ThreatShieldWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # OPENAI
  config :openai,
    # find it at https://platform.openai.com/account/api-keys
    api_key: System.get_env("OPENAI_API_KEY"),
    # find it at https://platform.openai.com/account/org-settings under "Organization ID"
    organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
    # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
    http_options: [recv_timeout: 30_000]

  # Configuring the mailer
  config :threat_shield, ThreatShield.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: System.get_env("MAILGUN_DOMAIN"),
    base_url: "https://api.eu.mailgun.net/v3"

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
end
