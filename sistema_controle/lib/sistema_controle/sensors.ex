defmodule SistemaControle.Sensors do
  import Ecto.Query
  alias SistemaControle.Schemas.SensorData
  alias SistemaControle.Devices
  alias SistemaControle.Repo

  @doc """
    Create a new sensor data entry
  """
  def create_sensor_data(attrs \\ %{}) do
    %SensorData{}
    |> SensorData.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Parse and create sensor data
  """
  def parse_and_create_sensor_data(payload, device_mac) do
    case Devices.get_device_by_mac(device_mac) do
      nil ->
        {:error, :device_not_found}

      device ->
        IO.inspect(device)

        sensor_data_attrs =
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
                pump_state: Map.get(data, "pump"),
                device_id: device.id
              }

            _ ->
              nil
          end

        case create_sensor_data(sensor_data_attrs) do
          {:ok, sensor_data} ->
            Devices.broadcast(device.id, {:new_sensor_data, sensor_data})
            {:ok, sensor_data}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
    Handle sensor data message from MQTT
  """
  def handle_sensor_message(type, payload, device_mac) do
    Devices.create_or_update_device(device_mac, type)
    parse_and_create_sensor_data(payload, device_mac)
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
    Get sensor data for a specific device
  """
  def get_sensor_data_by_device(device_id) do
    from(sd in SensorData,
      where: sd.device_id == ^device_id,
      order_by: [desc: sd.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
    Get last pump state for a specific device
  """
  def get_last_pump_state(device_id) do
    from(sd in SensorData,
      where: sd.device_id == ^device_id,
      order_by: [desc: sd.inserted_at],
      limit: 1,
      select: sd.pump_state
    )
    |> Repo.one()
  end

  @doc """
  Subscribe to all sensor messages
  """
  def subscribe_sensor_all do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "sensors:all")
  end

  def broadcast_sensor_all(message) do
    Phoenix.PubSub.broadcast(
      SistemaControle.PubSub,
      "sensors:all",
      message
    )
  end
end
