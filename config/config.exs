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
  # model_path: "models/catsdogs/cnn_catsdogs_50.h5",
  model_path: "models/ssd_mobilenet_v1/saved_model",
  image_path: "images/catsdogs/50"

# General application configuration
config :camera_mock,
  namespace: CameraMock,
  ecto_repos: [CameraMock.Repo]

# Configure your database
config :camera_mock, CameraMock.Repo,
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

# Configures the endpoint
config :camera_mock, CameraMockWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "kMbVD2uOELgrAnyuPSaRlGyYe0f09nugndt3HqOz/Cob9v/x7dtn+Sxha2KcmcJ/",
  render_errors: [view: CameraMockWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: CameraMock.PubSub, adapter: Phoenix.PubSub.PG2]

config :camera_mock, CameraMockWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :phoenix, :stacktrace_depth, 20

config :grpclassify, GRPClassify.Worker,
  target_url: "localhost:8000",
  streams_to_process: [0, 1, 2],
  classifier_url: "localhost:8001"

if Mix.env() == :test do
  import_config "test.exs"
end

config :camera_mock, CameraMock,
  drop_frames: System.get_env("DROP_FRAMES", "false") |> String.to_atom()

if System.get_env("DISABLE_LOGGING", "false") |> String.to_atom() do
  config :logger, backends: []
end
