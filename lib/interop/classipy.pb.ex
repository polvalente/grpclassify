defmodule Classipy.Image do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          filename: String.t(),
          height: non_neg_integer,
          width: non_neg_integer,
          content: binary
        }
  defstruct [:filename, :height, :width, :content]

  field :filename, 1, type: :string
  field :height, 2, type: :uint32
  field :width, 3, type: :uint32
  field :content, 4, type: :bytes
end

defmodule Classipy.ImageRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sender_pid: String.t(),
          images: Classipy.Image.t() | nil
        }
  defstruct [:sender_pid, :images]

  field :sender_pid, 1, type: :string
  field :images, 2, type: Classipy.Image
end

defmodule Classipy.ClassificationResult do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          category: String.t()
        }
  defstruct [:category]

  field :category, 1, type: :string
end

defmodule Classipy.ImageResult do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sender_pid: String.t(),
          classifications: Classipy.ClassificationResult.t() | nil,
          total_execution_time: non_neg_integer
        }
  defstruct [:sender_pid, :classifications, :total_execution_time]

  field :sender_pid, 1, type: :string
  field :classifications, 2, type: Classipy.ClassificationResult
  field :total_execution_time, 3, type: :uint32
end

defmodule Classipy.ImageClassifier.Service do
  @moduledoc false
  use GRPC.Service, name: "classipy.ImageClassifier"

  rpc :Classify, Classipy.ImageRequest, Classipy.ImageResult
end

defmodule Classipy.ImageClassifier.Stub do
  @moduledoc false
  use GRPC.Stub, service: Classipy.ImageClassifier.Service
end
