# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CameraMock.Repo.insert!(%CameraMock.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CameraMock.Repo

{:ok, _} = Application.ensure_all_started(:postgrex)
NimbleCSV.define(Parser, separator: "\t", escape: "\"")

priv_dir =
  :camera_mock
  |> :code.priv_dir()
  |> to_string()

base_path = Path.join([priv_dir, "/dataset/parsed_gt"])

base_path
|> File.ls!()
|> Enum.filter(&String.ends_with?(&1, ".csv"))
|> Enum.with_index()
|> Enum.each(fn {file, stream_id} ->
  path = Path.join([base_path, file])

  path
  |> File.stream!()
  |> NimbleCSV.RFC4180.parse_stream()
  |> Stream.map(fn [id, timestamp, num_people, filename] ->
    IO.puts("Saving frame #{id} of stream #{stream_id}")
    filename = Path.join([priv_dir, filename])
    frame_content = File.read!(filename)

    {id, ""} = Integer.parse(id)
    {num_people, ""} = Integer.parse(num_people)
    {timestamp, ""} = Float.parse(timestamp)

    Repo.insert!(%CameraMock.Schemas.Frame{
      stream_id: stream_id,
      id: id,
      timestamp: timestamp,
      num_people: num_people,
      content: frame_content
    })
  end)
  |> Stream.run()
end)
