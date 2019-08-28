# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :camera_mock,
  namespace: CameraMock,
  ecto_repos: [CameraMock.Repo]

# Configures the endpoint
config :camera_mock, CameraMockWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "kMbVD2uOELgrAnyuPSaRlGyYe0f09nugndt3HqOz/Cob9v/x7dtn+Sxha2KcmcJ/",
  render_errors: [view: CameraMockWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: CameraMock.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
