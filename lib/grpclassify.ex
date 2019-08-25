defmodule GRPClassify do
  @moduledoc """
  Documentation for GRPClassify.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GRPClassify.hello()
      :world

  """
  alias Classipy.{
    Image,
    ImageRequest,
    ImageClassifier.Stub
  }

  def classify(images, convert_to_grayscale?) do
    {:ok, channel} = GRPC.Stub.connect("localhost:8000")

    images =
      Enum.map(images, fn {bytes, filename} ->
        Image.new(filename: filename, content: bytes)
      end)

    req =
      ImageRequest.new(
        sender_pid: inspect(self()),
        images: images
      )

    res = Stub.classify(channel, req)

    GRPC.Stub.disconnect(channel)

    res
  end

  def run(images, convert_to_grayscale? \\ false)

  def run(images, convert_to_grayscale?) do
    classify(images, convert_to_grayscale?)
  end

  def run_from_disk(convert_to_grayscale?, n) do
    base_path = Path.join(config(:priv_dir), config(:image_path))

    filenames =
      base_path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".png"))
      |> Enum.take(n)

    filenames
    |> Enum.map(&load_as_bytes!(base_path, &1))
    |> Enum.zip(filenames)
    |> run(convert_to_grayscale?)
  end

  def benchmark() do
    %{year: year, month: month, day: day} = Date.utc_today()

    month_str =
      Enum.at(
        [
          "janeiro",
          "fevereiro",
          "março",
          "abril",
          "maio",
          "junho",
          "julho",
          "agosto",
          "setembro",
          "outubro",
          "novembro",
          "dezembro"
        ],
        month - 1
      )

    results =
      0..25
      |> Enum.map(fn run ->
        IO.inspect("Run #{run}")

        for n <- [1, 2, 5, 7, 10] do
          {micros, _} = :timer.tc(fn -> run_from_disk(false, n) end)
          %{n: n, millis_t: Float.round(micros / 1000, 3)}
        end
      end)
      |> List.flatten()
      |> Enum.group_by(&Map.get(&1, :n), &Map.get(&1, :millis_t))
      |> IO.inspect()
      |> Enum.map(fn {k, v} ->
        {avg, std_dev} = stats(v)
        {k, %{average: avg, std_dev: std_dev}}
      end)

    model =
      :model_path
      |> config()
      |> String.replace(~r<[/\.]>, "_")

    results
    |> format_latex()
    |> write_to_file("./results_#{model}_#{day}#{month_str}#{year}.tex")

    results
  end

  defp load_as_bytes!(base_path, path) do
    Path.join(base_path, path) |> File.read!()
  end

  defp config(:priv_dir), do: :code.priv_dir(:grpclassify)

  defp config(key) do
    :grpclassify
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end

  defp stats(l) do
    avg = fn x -> Enum.sum(x) / length(x) end

    mean = avg.(l)
    std_dev = avg.(Enum.map(l, &:math.pow(&1 - mean, 2))) |> :math.sqrt()

    {mean, std_dev}
  end

  defp format_latex(results) do
    header = ~S/
        \begin{table}[H]
          \centering
          \caption{Elixir - \textit{Benchmark} com gRPC$}
          \begin{tabular}{|r|r|r|}
            \hline
            Tamanho (\textit{Bytes}) & Tempo (Média) \\ \hline
            /

    lines =
      results
      |> Enum.map(&format_line/1)
      |> Enum.join("\n")

    footer = ~S/
          \end{tabular}
        \end{table}/

    Enum.join([header, lines, footer])
  end

  defp format_line({kB, %{average: avg, std_dev: std_dev}}) do
    ~S/$#{kB}$ kB & $#{avg} \pm #{std_dev}$ ms \\ \hline/
    |> String.replace(~S/#{kB}/, "#{kB}")
    |> String.replace(~S/#{avg}/, :erlang.float_to_binary(avg, decimals: 3))
    |> String.replace(~S/#{std_dev}/, :erlang.float_to_binary(std_dev, decimals: 3))
  end

  def write_to_file(content, filename) do
    IO.inspect(content)
    IO.inspect(filename)
    {:ok, file} = File.open(filename, [:write])
    IO.binwrite(file, content)
    File.close(file)
  end
end
