defmodule CameraMock.VideoStreamer do
  @moduledoc """
  This module takes care of loading all images from db into memory upon startup,
  so as to emulate streaming properly
  """

  use GenServer

  require Logger

  alias CameraMock.{
    Schemas.Frame,
    Repo
  }

  def init(_) do
    streams =
      Frame
      |> Repo.all()
      |> Enum.group_by(& &1.stream_id)
      |> Map.new(fn {stream_id, stream} ->
        frames = Map.new(stream, &{&1.id, &1})

        content =
          Map.merge(%{frames: frames}, %{
            last_fetched_at: Time.utc_now(),
            last_fetched_timestamp: nil
          })

        {stream_id, content}
      end)

    {:ok, %{streams: streams}}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reset, do: GenServer.cast(__MODULE__, :reset)

  def handle_cast(:reset, _) do
    {:ok, state} = init(nil)

    {:noreply, state}
  end

  def pop(stream_id, frame_id) do
    GenServer.call(__MODULE__, {:pop, stream_id, frame_id})
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def get_stream(stream_id) do
    GenServer.call(__MODULE__, {:get_stream, stream_id})
  end

  def get_frame(stream_id, frame_id, opts \\ [drop_frames: false]) do
    GenServer.call(__MODULE__, {:get_frame, stream_id, frame_id, opts})
  end

  def handle_call({:get_frame, stream_id, frame_id, drop_frames: false}, _from, state) do
    {:reply,
     state.streams |> Map.get(stream_id, %{}) |> Map.get(:frames, %{}) |> Map.get(frame_id),
     state}
  end

  def handle_call({:get_frame, stream_id, frame_id, drop_frames: true}, _from, state) do
    stream = get_stream_from_state(state, stream_id)
    frames = Map.get(stream, :frames, %{})
    frame = Map.get(frames, frame_id)
    now = Time.utc_now()
    {state, frame} = decide_if_will_drop(state, frame, stream_id, now)

    {:reply, frame, state}
  end

  def handle_call({:get_stream, stream_id}, _from, state) do
    {:reply, Map.get(state.streams, stream_id), state}
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:pop, stream_id, frame_id}, _from, state) do
    {frame, state} = pop_in(state, [:streams, stream_id, frame_id])

    {:reply, frame, state}
  end

  defp get_stream_from_state(state, stream_id) do
    state
    |> Map.get(:streams, %{})
    |> Map.get(stream_id, %{})
  end

  defp decide_if_will_drop(state, nil, _stream_id, _now), do: {state, nil}

  defp decide_if_will_drop(state, frame, stream_id, now) do
    frame =
      state
      |> get_stream_from_state(stream_id)
      |> case do
        %{last_fetched_timestamp: nil} ->
          frame

        stream ->
          t_diff = Time.diff(now, stream.last_fetched_at, :microsecond)

          frame =
            if t_diff > (frame.timestamp - stream.last_fetched_timestamp) * 1_000_000 do
              Logger.error("Skipping frame #{frame.id} from stream #{stream_id}")

              stream.frames
              |> Map.values()
              |> Enum.sort_by(fn x ->
                x.timestamp
              end)
              |> Enum.reject(fn %{timestamp: timestamp} ->
                timestamp <= frame.timestamp
              end)
              |> Enum.reject(fn %{timestamp: timestamp} ->
                t = timestamp * 1_000_000
                t <= t_diff + stream.last_fetched_timestamp * 1_000_000
              end)
              |> Enum.at(0, frame)
            else
              frame
            end

          frame
      end

    Logger.info("Returning #{frame.id} from stream #{stream_id}")

    state =
      state
      |> put_in([:streams, stream_id, :last_fetched_timestamp], frame.timestamp)
      |> put_in([:streams, stream_id, :last_fetched_at], now)

    {state, frame}
  end
end
