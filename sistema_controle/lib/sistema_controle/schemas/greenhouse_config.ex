defmodule SistemaControle.Schemas.GreenhouseConfig do
  use Ecto.Schema

  import Ecto.Changeset

  schema "greenhouse_configs" do
    field :name, :string
    field :min_ph, :float
    field :ideal_ph, :float
    field :max_ph, :float
    field :min_ec, :float
    field :ideal_ec, :float
    field :max_ec, :float
    field :min_water_temp, :float
    field :ideal_water_temp, :float
    field :max_water_temp, :float
    field :min_air_temp, :float
    field :ideal_air_temp, :float
    field :max_air_temp, :float
    field :min_air_humidity, :float
    field :ideal_air_humidity, :float
    field :max_air_humidity, :float
    field :crop_name, :string

    belongs_to :device, SistemaControle.Schemas.Device

    timestamps()
  end

  def changeset(greenhouse_config, attrs) do
    greenhouse_config
    |> cast(attrs, [
      :name,
      :min_ph,
      :ideal_ph,
      :max_ph,
      :min_ec,
      :ideal_ec,
      :max_ec,
      :min_water_temp,
      :ideal_water_temp,
      :max_water_temp,
      :min_air_temp,
      :ideal_air_temp,
      :max_air_temp,
      :min_air_humidity,
      :ideal_air_humidity,
      :max_air_humidity,
      :crop_name,
      :device_id
    ])
    |> validate_required([
      :name,
      :min_ph,
      :ideal_ph,
      :max_ph,
      :min_ec,
      :ideal_ec,
      :max_ec,
      :min_water_temp,
      :ideal_water_temp,
      :max_water_temp,
      :min_air_temp,
      :ideal_air_temp,
      :max_air_temp,
      :min_air_humidity,
      :ideal_air_humidity,
      :max_air_humidity,
      :crop_name,
      :device_id
    ])
  end
end
