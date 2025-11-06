defmodule SistemaControle.Greenhouse do
  import Ecto.Query
  alias SistemaControle.Schemas.GreenhouseConfig
  alias SistemaControle.Schemas.Device
  alias SistemaControle.Schemas.SensorData
  alias SistemaControle.Repo

  def change_greenhouse_config(%GreenhouseConfig{} = greenhouse_config, attrs \\ %{}) do
    GreenhouseConfig.changeset(greenhouse_config, attrs)
  end

  @doc """
    Get greenhouse configuration by device ID
  """
  def get_greenhouse_config(device_id) do
    Repo.get_by(GreenhouseConfig, device_id: device_id)
  end

  @doc """
    Get all greenhouses with last sensor data
  """
  def get_all() do
    subquery_latest_data =
      from(sd in SensorData,
        distinct: sd.device_id,
        order_by: [desc: sd.inserted_at],
        select: %{device_id: sd.device_id, id: sd.id}
      )

    from(gc in GreenhouseConfig,
      join: d in Device,
      on: gc.device_id == d.id,
      left_join: sdl in subquery(subquery_latest_data),
      on: sdl.device_id == d.id,
      left_join: sd in SensorData,
      on: sd.id == sdl.id,
      preload: [device: d],
      select: %{
        greenhouse: gc,
        latest_sensor_data: sd
      }
    )
    |> Repo.all()
  end

  @doc """
    Update greenhouse configuration
  """
  def update(_, attrs \\ %{})

  def update(%GreenhouseConfig{} = greenhouse_config, attrs) do
    greenhouse_config
    |> change_greenhouse_config(attrs)
    |> Repo.update()
  end

  def update(device_id, attrs) do
    case get_greenhouse_config(device_id) do
      nil ->
        {:error, :not_found}

      greenhouse_config ->
        greenhouse_config
        |> GreenhouseConfig.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
    Create greenhouuse config if not exists
  """
  def create_if_not_exists(device_id) do
    case get_greenhouse_config(device_id) do
      nil ->
        IO.inspect("Criando greenhouse config padrao para device_id #{device_id}")

        %GreenhouseConfig{}
        |> GreenhouseConfig.changeset(%{
          name: "Estufa #{device_id}",
          device_id: device_id,
          min_ph: 5.5,
          ideal_ph: 6.0,
          max_ph: 6.5,
          min_ec: 800.0,
          ideal_ec: 1200.0,
          max_ec: 1600.0,
          min_water_temp: 18.0,
          ideal_water_temp: 22.0,
          max_water_temp: 26.0,
          min_air_temp: 20.0,
          ideal_air_temp: 24.0,
          max_air_temp: 28.0,
          min_air_humidity: 60.0,
          ideal_air_humidity: 70.0,
          max_air_humidity: 80.0,
          crop_name: "Alface"
        })
        |> Repo.insert()

      _greenhouse_config ->
        IO.inspect("Greenhouse config ja existe para device_id #{device_id}")
        :ok
    end
  end

  def broadcast_new(device) do
    case get_greenhouse_config(device.id) do
      nil ->
        :ok

      greenhouse_config ->
        item = %{
          id: greenhouse_config.id,
          greenhouse: Repo.preload(greenhouse_config, :device),
          latest_sensor_data: nil
        }

        broadcast_all({:new_greenhouse, item})
    end
  end

  def broadcast_update(device_id, sensor_data) do
    case get_greenhouse_config(device_id) do
      nil ->
        :ok

      greenhouse_config ->
        item = %{
          id: greenhouse_config.id,
          greenhouse: Repo.preload(greenhouse_config, :device),
          latest_sensor_data: sensor_data
        }

        broadcast_all({:greenhouse_update, item})
    end
  end

  def subscribe_all() do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "greenhouse:all")
  end

  def broadcast_all(message) do
    Phoenix.PubSub.broadcast(SistemaControle.PubSub, "greenhouse:all", message)
  end
end
