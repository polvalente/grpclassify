defmodule CameraMock.Repo.Migrations.AddFrames do
  use Ecto.Migration

  def change do
    create table("frames", primary_key: false) do
      add(:id, :bigint, primary_key: true)
      add(:stream_id, :integer, primary_key: true)
      add(:content, :binary)
      add(:timestamp, :float)
      add(:num_people, :integer)

      timestamps()
    end
  end
end
