use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :camera_mock, CameraMockWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :camera_mock, CameraMock.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "camera_mock_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
