defmodule CameraMockWeb.Router do
  use CameraMockWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CameraMockWeb do
    pipe_through :api
  end
end
