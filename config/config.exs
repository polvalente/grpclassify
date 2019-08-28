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

config :grpc, start_server: true

if Mix.env() == :test do
  import_config "test.exs"
end
