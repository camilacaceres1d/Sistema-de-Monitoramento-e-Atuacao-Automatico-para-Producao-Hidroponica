defmodule SistemaControle.Greenhouse do
  import Ecto.Query
  alias SistemaControle.Schemas.GreenhouseConfig
  alias SistemaControle.Schemas.Device
  alias SistemaControle.Schemas.SensorData
  alias SistemaControle.Repo
  alias SistemaControle.Devices

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
    Get associated benchs
  """
  def get_associated_benchs(device_id) do
    from(d in Device,
      where: d.greenhouse_id == ^device_id,
      select: d
    )
    |> Repo.all()
  end

  @doc """
    Link a bench to a greenhose
  """
  def link_bench(greenhouse_id, bench_id) do
    case Repo.get(Device, bench_id) do
      nil ->
        {:error, :bench_not_found}

      bench ->
        bench
        |> Device.changeset(%{greenhouse_id: greenhouse_id})
        |> Repo.update()
    end
  end

  @doc """
    Unlink a bench from a greenhouse
  """
  def unlink_bench(bench_id) do
    case Repo.get(Device, bench_id) do
      nil ->
        {:error, :bench_not_found}

      bench ->
        bench
        |> Device.changeset(%{greenhouse_id: nil})
        |> Repo.update()
    end
  end

  def get_all() do
    sub_latest =
      from(sd in SensorData,
        distinct: sd.device_id,
        order_by: [desc: sd.inserted_at],
        select: %{device_id: sd.device_id, id: sd.id}
      )

    sub_avg_bench =
      from(b in Device,
        where: b.type == :bench,
        left_join: sdl in subquery(sub_latest),
        on: sdl.device_id == b.id,
        left_join: sd in SensorData,
        on: sd.id == sdl.id,
        group_by: b.greenhouse_id,
        select: %{
          greenhouse_id: b.greenhouse_id,
          avg_air_temp: avg(sd.air_temperature),
          avg_air_humidity: avg(sd.air_humidity),
          avg_water_flow: avg(sd.water_flow)
        }
      )

    from(gc in GreenhouseConfig,
      join: d in Device,
      on: gc.device_id == d.id,
      left_join: sdl in subquery(sub_latest),
      on: sdl.device_id == d.id,
      left_join: sd in SensorData,
      on: sd.id == sdl.id,
      left_join: avg_b in subquery(sub_avg_bench),
      on: avg_b.greenhouse_id == d.id,
      where: d.type == :greenhouse,
      preload: [device: d],
      select: {gc, sd, avg_b}
    )
    |> Repo.all()
    |> Enum.map(fn {greenhouse, latest_sensor_data, avg_bench} ->
      %{
        id: greenhouse.id,
        greenhouse: greenhouse,
        latest_sensor_data: latest_sensor_data,
        avg_air_temp: avg_bench && avg_bench.avg_air_temp,
        avg_air_humidity: avg_bench && avg_bench.avg_air_humidity,
        avg_water_flow: avg_bench && avg_bench.avg_water_flow
      }
    end)
  end

  @doc """
    Get device from greenhouse config id
  """
  def get_device_from_config(greenhouse_config_id) do
    case Repo.get(GreenhouseConfig, greenhouse_config_id) do
      nil -> nil
      greenhouse_config -> Repo.get(Device, greenhouse_config.device_id)
    end
  end

  @doc """
    Set pump state
  """
  def set_pump_state(device, state) do
    SistemaControle.Devices.send_pump_command(device.device_mac, state)
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
        :ok
    end
  end

  @doc """
    Get all sensor data by greenhouse and its benchs
  """
  def get_all_sensor_data(greenhouse_id) do
    from(sd in SensorData,
      join: d in assoc(sd, :device),
      where: d.greenhouse_id == ^greenhouse_id or d.id == ^greenhouse_id,
      order_by: [desc: sd.inserted_at],
      limit: 100,
      preload: [:device]
    )
    |> Repo.all()
  end

  @doc """
    Get light state by greenhouse
  """
  def get_light_state(greenhouse_id) do
    latest_per_device =
      from(sd in SensorData,
        join: d in assoc(sd, :device),
        where: d.greenhouse_id == ^greenhouse_id and d.type == :bench,
        distinct: d.id,
        order_by: [d.id, desc: sd.inserted_at],
        select: sd.light_state
      )
      |> Repo.all()

    case Enum.frequencies(latest_per_device) do
      %{true => t, false => f} when t > f -> true
      %{true => _t, false => _f} -> false
      %{true => _t} -> true
      _ -> false
    end
  end

  @doc """
    Toggle all lights in the greenhouse benches
  """
  def toggle_lights(greenhouse_id, state) do
    benches = get_associated_benchs(greenhouse_id)

    Enum.each(benches, fn bench ->
      Devices.send_light_command(bench.device_mac, state)
    end)
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
        avg_data = calculate_bench_averages(device_id)

        item = %{
          id: greenhouse_config.id,
          greenhouse: Repo.preload(greenhouse_config, :device),
          latest_sensor_data: sensor_data,
          avg_air_temp: avg_data.avg_air_temp,
          avg_air_humidity: avg_data.avg_air_humidity,
          avg_water_flow: avg_data.avg_water_flow
        }

        broadcast_all({:greenhouse_update, item})
    end
  end

  defp calculate_bench_averages(greenhouse_id) do
    sub_latest =
      from(sd in SensorData,
        distinct: sd.device_id,
        order_by: [desc: sd.inserted_at],
        select: %{device_id: sd.device_id, id: sd.id}
      )

    result =
      from(b in Device,
        where: b.type == :bench and b.greenhouse_id == ^greenhouse_id,
        left_join: sdl in subquery(sub_latest),
        on: sdl.device_id == b.id,
        left_join: sd in SensorData,
        on: sd.id == sdl.id,
        select: %{
          avg_air_temp: avg(sd.air_temperature),
          avg_air_humidity: avg(sd.air_humidity),
          avg_water_flow: avg(sd.water_flow)
        }
      )
      |> Repo.one()

    result || %{avg_air_temp: nil, avg_air_humidity: nil, avg_water_flow: nil}
  end

  def subscribe_all() do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "greenhouse:all")
  end

  def broadcast_all(message) do
    Phoenix.PubSub.broadcast(SistemaControle.PubSub, "greenhouse:all", message)
  end
end
