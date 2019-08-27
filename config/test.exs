use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :video_server, VideoServerWeb.Endpoint,
  http: [port: 4001],
  server: false

# Configure your database
config :video_server, VideoServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "video_server_test",
  hostname: "localhost",
  port: 5437,
  pool: Ecto.Adapters.SQL.Sandbox
