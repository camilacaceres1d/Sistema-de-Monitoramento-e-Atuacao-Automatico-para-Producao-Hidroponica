defmodule SistemaControle.MqttClient do
  use GenServer
  require Logger

  @greenhouse_topic "greenhouse/+/sensors"
  @bench_topic "bench/+/sensors"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    opts = [
      host: "localhost",
      port: 1883,
      username: "hidroponia",
      password: "Hidroponia@123",
      clientid: "control_system",
      clean_start: true
    ]

    case :emqtt.start_link(opts) do
      {:ok, client} when is_pid(client) ->
        case :emqtt.connect(client) do
          {:ok, _props} ->
            topic = @greenhouse_topic
            topic2 = @bench_topic

            case :emqtt.subscribe(client, topic, qos: 0) do
              {:ok, _, _} ->
                Logger.info("Subscribed to: #{topic}")
                {:ok, %{client: client}}

              {:error, reason} ->
                Logger.error("Error subscribing to #{topic}: #{inspect(reason)}")
                {:stop, {:connect_error, reason}}
            end

            case :emqtt.subscribe(client, topic2, qos: 0) do
              {:ok, _, _} ->
                Logger.info("Subscribed to: #{topic2}")
                {:ok, %{client: client}}

              {:error, reason} ->
                Logger.error("Error subscribing to #{topic2}: #{inspect(reason)}")
                {:stop, {:connect_error, reason}}
            end

          {:error, reason} ->
            Logger.error("Failed to connect to MQTT broker: #{inspect(reason)}")
            {:stop, reason}
        end

      {:error, reason} ->
        Logger.error("Failed to start MQTT client: #{inspect(reason)}")
        {:stop, reason}

      other ->
        Logger.error("Unexpected result starting MQTT client: #{inspect(other)}")
        {:stop, :unexpected_result}
    end
  end

  def publish(topic, message) do
    GenServer.call(__MODULE__, {:publish, topic, message})
  end

  @impl true
  def handle_call({:publish, topic, message}, _from, %{client: client} = state) do
    case :emqtt.publish(client, topic, message, qos: 0) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("Failed to publish message to #{topic}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(_req, _from, state) do
    {:reply, {:error, :client_not_available}, state}
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    try do
      case String.split(topic, "/") do
        ["greenhouse", device_mac, "sensors"] ->
          SistemaControle.Sensors.handle_sensor_message(:greenhouse, payload, device_mac)

        ["bench", device_mac, "sensors"] ->
          SistemaControle.Sensors.handle_sensor_message(:bench, payload, device_mac)

        _ ->
          Logger.warning("Invalid topic format: #{topic}")
      end
    rescue
      error ->
        Logger.error("Error processing mqtt message: #{inspect(error)}")
        Logger.error("Topic: #{topic}, Payload: #{payload}")
    end

    {:noreply, state}
  end

  def handle_info({:disconnected, reason}, state) do
    Logger.warning("Disconnected from MQTT broker: #{inspect(reason)}")
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    # Mensagem nao tratada corretamente
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %{client: client}) do
    Logger.info("Terminating MQTT client: #{inspect(reason)}")
    :emqtt.disconnect(client)
    :emqtt.stop(client)
    :ok
  end

  def terminate(_reason, _state) do
    :ok
  end
end
