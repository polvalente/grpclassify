defmodule CameraMock do
  @moduledoc """
  CameraMock keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias CameraMock.VideoStreamer

  alias VideoServer.{
    Frame,
    Request,
    Response,
    Streamer
  }

  use GRPC.Server, service: Streamer.Service

  @spec get_frame(Request.t(), GRPC.Server.Stream.t()) :: Response.t()
  def get_frame(%Request{stream_id: stream_id, frame_id: frame_id}, _grpc_stream) do
    opts = Application.get_env(:camera_mock, __MODULE__, drop_frames: false)

    stream_id
    |> VideoStreamer.get_frame(frame_id, opts)
    |> case do
      nil ->
        Response.new(frame: Frame.new(), next_frame_id: -1)

      fetched ->
        params = Map.from_struct(fetched)
        frame = struct(Frame, params)
        Response.new(frame: frame, next_frame_id: frame.id + 1)
    end
  end
end
