defmodule GRPClassify.Worker do
  use GenServer

  require Logger

  alias GRPClassify.ClassificationStorage

  def init(_) do
    target_url = config()[:target_url]
    classifier_url = config()[:classifier_url]
    target_streams = config()[:streams_to_process]

    targets = Map.new(target_streams, &{&1, %{current_frame_id: 0}})

    state = %{target_url: target_url, target_streams: targets, classifier_url: classifier_url}
    schedule_work()

    {:ok, state}
  end

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reset, do: GenServer.cast(__MODULE__, :reset)

  def handle_cast(:reset, _) do
    {:ok, state} = init(nil)

    {:noreply, state}
  end

  def handle_info(
        :fetch_frames,
        %{target_url: target_url, target_streams: target_streams, classifier_url: classifier_url} =
          state
      ) do
    Logger.info("Fetching new frames")

    start_time = Time.utc_now()
    {:ok, channel} = GRPC.Stub.connect(target_url)
    Logger.debug("Connected to streamer", streams: inspect(target_streams))

    responses =
      Enum.map(target_streams, fn {stream, %{current_frame_id: frame}} ->
	Logger.debug("Fetching stream", stream_id: inspect(stream), frame_id: inspect(frame))
        request = VideoServer.Request.new(stream_id: stream, frame_id: frame)
        {:ok, frame} = VideoServer.Streamer.Stub.get_frame(channel, request)
        {stream, frame}
      end)

    GRPC.Stub.disconnect(channel)
    Logger.debug("Disconnected from streamer")

    responses =
      responses
      |> Enum.to_list()
      |> Enum.sort_by(fn {key, _value} -> key end)

    ordered_frames =
      responses
      |> Keyword.values()

    state =
      Enum.reduce(responses, state, fn
        {_, %{next_frame_id: -1}}, _ ->
          :ok = GenServer.call(ClassificationStorage, :process_results)
          GenServer.stop(__MODULE__, :reached_stream_end)

        {stream_id, %{next_frame_id: next_frame}}, state ->
          put_in(state, [:target_streams, stream_id, :current_frame_id], next_frame)
      end)

    images =
      responses
      |> Enum.map(fn {stream_id, %{frame: %{content: content}}} ->
        Classipy.Image.new(filename: to_string(stream_id), content: content)
      end)

    Logger.info("Connecting to classifier")
    {:ok, channel} = GRPC.Stub.connect(classifier_url)
    Logger.debug("Connected to classifier")

    request = Classipy.ImageRequest.new(sender_pid: "#{__MODULE__}", images: images)

    timeout = 300_000

    {:ok, classification_responses} =
      Classipy.ImageClassifier.Stub.classify(channel, request, timeout: timeout)

    GRPC.Stub.disconnect(channel)

    timestamps =
      ordered_frames
      |> Enum.map(& &1.frame.timestamp)

    end_time = Time.utc_now()

    :ok =
      GenServer.cast(
        ClassificationStorage,
        {:save,
         %{
           responses: classification_responses,
           total_call_time: Time.diff(end_time, start_time, :microsecond),
           timestamps: timestamps
         }}
      )

    schedule_work(0)
    {:noreply, state}
  rescue
    error ->
      Logger.error("Failed to fetch frames", reason: inspect(error))
      schedule_work(15)
      {:noreply, state}
  end

  defp schedule_work(time \\ 30) do
    Logger.info("Scheduling work")
    Process.send_after(__MODULE__, :fetch_frames, time)
  end

  defp config, do: Application.get_env(:grpclassify, GRPClassify.Worker)
end
