defmodule SistemaControle.Greenhouse do
  import Ecto.Query
  alias SistemaControle.Schemas.GreenhouseConfig
  alias SistemaControle.Schemas.Device
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
    Get all greenhouses
  """
  def get_all() do
    Repo.all(
      from gc in GreenhouseConfig,
        join: d in Device,
        on: gc.device_id == d.id,
        preload: [device: d]
    )
  end

  @doc """
    Update greenhouse configuration
  """
  def update(_, attrs \\ %{})

  def update(%GreenhouseConfig{} = greenhouse_config, attrs) do
    greenhouse_config
    |> GreenhouseConfig.changeset(attrs)
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
end
