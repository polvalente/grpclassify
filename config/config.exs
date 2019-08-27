# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

import Config

config :grpclassify, GRPClassify,
  model_path: "models/catsdogs/cnn_catsdogs_50.h5",
  image_path: "images/catsdogs/50"

# General application configuration
config :video_server,
  namespace: VideoServer,
  ecto_repos: [VideoServer.Repo]

# Configures the endpoint
config :video_server, VideoServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/eAJgbdM3gZfL5V5Z26OQmOWXeS1xycWAHEDifr2qGhWP33IXr9c1byzjnwXId/E",
  render_errors: [view: VideoServerWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: VideoServer.PubSub, adapter: Phoenix.PubSub.PG2]

config :video_server, VideoServerWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :video_server, VideoServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "video_server_dev",
  hostname: "localhost",
  port: "5432",
  pool_size: 10

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: :all

if Mix.env() == :test do
  import_config "test.exs"
end
