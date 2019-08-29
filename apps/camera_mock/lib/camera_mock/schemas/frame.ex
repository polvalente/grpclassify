defmodule CameraMock.Schemas.Frame do
  use Ecto.Schema

  @primary_key false
  schema "frames" do
    field(:id, :integer, primary_key: true)
    field(:stream_id, :integer)
    field(:content, :binary)
    field(:timestamp, :float)
    field(:num_people, :integer)

    timestamps()
  end
end
