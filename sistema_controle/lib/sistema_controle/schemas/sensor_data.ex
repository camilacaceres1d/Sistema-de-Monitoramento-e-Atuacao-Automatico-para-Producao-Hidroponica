defmodule SistemaControle.Schemas.SensorData do
  use Ecto.Schema

  import Ecto.Changeset

  schema "sensor_data" do
    field :air_humidity, :float
    field :air_temperature, :float
    field :ph, :float
    field :ec, :float
    field :water_flow, :float
    field :water_temperature, :float
    field :level0, :boolean
    field :level1, :boolean
    field :level2, :boolean
    field :pump_state, :boolean

    belongs_to :device, SistemaControle.Schemas.Device
    timestamps()
  end

  @doc false
  def changeset(device_data, attrs) do
    device_data
    |> cast(attrs, [
      :ph,
      :ec,
      :water_temperature,
      :air_temperature,
      :air_humidity,
      :water_flow,
      :level0,
      :level1,
      :level2,
      :pump_state,
      :device_id
    ])
    |> validate_required([:device_id])
  end
end
