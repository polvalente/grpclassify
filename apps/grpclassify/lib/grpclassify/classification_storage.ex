defmodule GRPClassify.ClassificationStorage do
  use GenServer

  def init(_) do
    {:ok, %{streams: %{}}}
  end

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def state, do: GenServer.call(__MODULE__, :state)

  def reset, do: GenServer.cast(__MODULE__, :reset)

  def handle_call(
        :state,
        _caller,
        state
      ),
      do: {:reply, state, state}

  def handle_call(:process_results, _from, state) do
    timestamp =
      NaiveDateTime.utc_now()
      |> to_string()
      |> String.replace(~r/\s/, "_")

    filename =
      :grpclassify
      |> :code.priv_dir()
      |> to_string()
      |> Path.join("results/#{timestamp}_results.json")

    json_content =
      state.streams
      |> Map.new(fn {key, value} -> {key, Map.take(value, [:timestamps, :total_call_times])} end)
      |> Poison.encode!()

    File.write!(filename, json_content)

    {:reply, :ok, state}
  end

  def handle_cast(:reset, _) do
    {:ok, state} = init(nil)

    {:noreply, state}
  end

  def handle_cast(
        {:save,
         %{
           responses: response,
           total_call_time: total_call_time,
           timestamps: timestamps
         }},
        state
      ) do
    updated_state =
      response
      |> Map.get(:classifications)
      |> Enum.with_index()
      |> Enum.reduce(state, fn {%{category: category}, stream_id}, acc ->
        update_in(acc, [:streams, stream_id], fn
          nil ->
            %{
              timestamps: [Enum.at(timestamps, stream_id)],
              classifications: [category],
              total_call_times: [total_call_time]
            }

          %{timestamps: t, classifications: c, total_call_times: tct} ->
            %{
              timestamps: t ++ [Enum.at(timestamps, stream_id)],
              classifications: c ++ [category],
              total_call_times: tct ++ [total_call_time]
            }
        end)
      end)

    {:noreply, updated_state}
  end
end
