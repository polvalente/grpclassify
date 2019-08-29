defmodule CameraMock.Application do
  use Application

  alias CameraMock.VideoStreamer
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(CameraMock.Repo, []),
      # Start the endpoint when the application starts
      supervisor(CameraMockWeb.Endpoint, []),
      {VideoStreamer, []},
      supervisor(GRPC.Server.Supervisor, [{CameraMock.Interop.Endpoint, 8000}])
      # Start your own worker by calling: CameraMock.Worker.start_link(arg1, arg2, arg3)
      # worker(CameraMock.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CameraMock.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CameraMockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
