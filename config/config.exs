# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :superlogica,
  ecto_repos: [Superlogica.Repo]

# Configures the endpoint
config :superlogica, SuperlogicaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "E3jcfL6BKzqnCJKHu0dfIBFW9ktN8YrGxBUHmUxe4byO2knZnF6Xqy/loeq6sYFn",
  render_errors: [view: SuperlogicaWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Superlogica.PubSub,
  live_view: [signing_salt: "hC9X2iy4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

#
# tzdata
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# elastic
config :elastix,
  json_options: [keys: :atoms],
  json_codec: Jason,
  elastic_url: "http://192.168.0.201:9200/",
  httpoison_options: [hackney: [pool: :elastix_pool]]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
