defmodule SistemaControle.Sensors do
  import Ecto.Query
  alias SistemaControle.Schemas.SensorData
  alias SistemaControle.Repo

  @doc """
  Create a new sensor data entry
  """
  def create_sensor_data(attrs \\ %{}) do
    %SensorData{}
    |> SensorData.changeset(attrs)
    |> SistemaControle.Repo.insert()
  end

  @doc """
    Handle sensor data message from MQTT
  """
  def handle_sensor_message(payload) do
    parsed_message =
      case Jason.decode(payload) do
        {:ok, data} when is_map(data) ->
          %{
            ph: Map.get(data, "ph"),
            ec: Map.get(data, "ec"),
            water_temperature: Map.get(data, "temp"),
            air_temperature: Map.get(data, "air_temperature"),
            air_humidity: Map.get(data, "air_humidity"),
            water_flow: Map.get(data, "water_flow"),
            level0: get_in(data, ["levels", "level0"]),
            level1: get_in(data, ["levels", "level1"]),
            level2: get_in(data, ["levels", "level2"]),
            pump_state: Map.get(data, "pump")
          }

        _ ->
          nil
      end

    case create_sensor_data(parsed_message) do
      {:ok, sensor_data} ->
        broadcast_all({:new_sensor_data, sensor_data})
        {:ok, sensor_data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Get all sensor data
  """
  def get_all_sensor_data() do
    from(sd in SensorData,
      order_by: [desc: sd.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Subscribe to updates from a greenhouse
  """
  def subscribe(mac) do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "greenhouse:#{mac}")
  end

  def broadcast(mac, message) do
    Phoenix.PubSub.broadcast(
      SistemaControl.PubSub,
      "greenhouse:#{mac}",
      message
    )
  end

  @doc """
  Subscribe to all sensor messages
  """
  def subscribe_all do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "sensors:all")
  end

  def broadcast_all(message) do
    Phoenix.PubSub.broadcast(
      SistemaControle.PubSub,
      "sensors:all",
      message
    )
  end
end
