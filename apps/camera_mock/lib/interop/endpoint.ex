# Define your endpoint
defmodule CameraMock.Interop.Endpoint do
  use GRPC.Endpoint

  intercept(GRPC.Logger.Server)
  run(CameraMock)
end
