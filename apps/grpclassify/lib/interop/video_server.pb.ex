defmodule VideoServer.Frame do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          timestamp: float,
          id: non_neg_integer,
          height: non_neg_integer,
          width: non_neg_integer,
          content: binary
        }
  defstruct [:timestamp, :id, :height, :width, :content]

  field :timestamp, 1, type: :float
  field :id, 2, type: :uint32
  field :height, 3, type: :uint32
  field :width, 4, type: :uint32
  field :content, 5, type: :bytes
end

defmodule VideoServer.Request do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          stream_id: non_neg_integer,
          frame_id: non_neg_integer
        }
  defstruct [:stream_id, :frame_id]

  field :stream_id, 1, type: :uint32
  field :frame_id, 2, type: :uint32
end

defmodule VideoServer.Response do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          frame: VideoServer.Frame.t() | nil,
          next_frame_id: integer
        }
  defstruct [:frame, :next_frame_id]

  field :frame, 1, type: VideoServer.Frame
  field :next_frame_id, 2, type: :int32
end

defmodule VideoServer.Streamer.Service do
  @moduledoc false
  use GRPC.Service, name: "video_server.Streamer"

  rpc :get_frame, VideoServer.Request, VideoServer.Response
end

defmodule VideoServer.Streamer.Stub do
  @moduledoc false
  use GRPC.Stub, service: VideoServer.Streamer.Service
end
