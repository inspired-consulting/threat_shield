# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Load environment variables from .env file
dotenv_path = Path.expand("../.env", __DIR__)

if File.exists?(dotenv_path) do
  File.read!(dotenv_path)
  |> String.split("\n")
  |> Enum.filter(&String.contains?(&1, "="))
  |> Enum.each(fn line ->
    [key, value] = String.trim(line) |> String.split("=", parts: 2)
    System.put_env(key, value)
  end)
end

config :threat_shield,
  ecto_repos: [ThreatShield.Repo]

# Configures the endpoint
config :threat_shield, ThreatShieldWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: ThreatShieldWeb.ErrorHTML, json: ThreatShieldWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ThreatShield.PubSub,
  live_view: [signing_salt: "TOOUQx8Y"],
  git_version: System.get_env("GIT_VERSION_TAG", "version_not_found")

# Configures Elixir's Logger
config :logger_json, :backend,
  format: "$message\n",
  metadata: :all,
  json_encoder: Jason,
  formatter: LoggerJSON.Formatters.GoogleCloudLogger

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :threat_shield, ThreatShield.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Rate-limiting
config :ex_rated,
  timeout: 24 * 60 * 60 * 1000,
  cleanup_rate: 60 * 60 * 1000,
  persistent: false,
  name: :ex_rated,
  ets_table_name: :ex_rated_buckets

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
