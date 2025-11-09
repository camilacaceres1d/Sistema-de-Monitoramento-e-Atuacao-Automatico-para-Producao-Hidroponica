defmodule SistemaControle.Schemas.GreenhouseConfig do
  use Ecto.Schema

  import Ecto.Changeset

  schema "greenhouse_configs" do
    field(:name, :string)
    field(:min_ph, :float)
    field(:ideal_ph, :float)
    field(:max_ph, :float)
    field(:min_ec, :float)
    field(:ideal_ec, :float)
    field(:max_ec, :float)
    field(:min_water_temp, :float)
    field(:ideal_water_temp, :float)
    field(:max_water_temp, :float)
    field(:min_air_temp, :float)
    field(:ideal_air_temp, :float)
    field(:max_air_temp, :float)
    field(:min_air_humidity, :float)
    field(:ideal_air_humidity, :float)
    field(:max_air_humidity, :float)
    field(:crop_name, :string)

    belongs_to(:device, SistemaControle.Schemas.Device)

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
    |> validate_fields()
    |> validate_number(:min_ph,
      greater_than_or_equal_to: 0,
      message: "O pH deve ser maior ou igual a 0"
    )
    |> validate_number(:ideal_ph,
      greater_than_or_equal_to: 0,
      message: "O pH deve ser maior ou igual a 0"
    )
    |> validate_number(:max_ph,
      greater_than_or_equal_to: 0,
      message: "O pH deve ser maior ou igual a 0"
    )
    |> validate_number(:min_air_humidity,
      greater_than_or_equal_to: 0,
      message: "A umidade do ar deve ser maior ou igual a 0"
    )
    |> validate_number(:ideal_air_humidity,
      greater_than_or_equal_to: 0,
      message: "A umidade do ar deve ser maior ou igual a 0"
    )
    |> validate_number(:max_air_humidity,
      greater_than_or_equal_to: 0,
      message: "A umidade do ar deve ser maior ou igual a 0"
    )
    |> validate_number(:min_ph,
      less_than_or_equal_to: 14,
      message: "O pH deve ser menor ou igual a 14"
    )
    |> validate_number(:ideal_ph,
      less_than_or_equal_to: 14,
      message: "O pH deve ser menor ou igual a 14"
    )
    |> validate_number(:max_ph,
      less_than_or_equal_to: 14,
      message: "O pH deve ser menor ou igual a 14"
    )
    |> validate_number(:min_air_humidity,
      less_than_or_equal_to: 100,
      message: "A umidade do ar deve ser menor ou igual a 100"
    )
    |> validate_number(:ideal_air_humidity,
      less_than_or_equal_to: 100,
      message: "A umidade do ar deve ser menor ou igual a 100"
    )
    |> validate_number(:max_air_humidity,
      less_than_or_equal_to: 100,
      message: "A umidade do ar deve ser menor ou igual a 100"
    )
  end

  def validate_fields(changeset) do
    fields = [
      :ph,
      :ec,
      :water_temp,
      :air_temp,
      :air_humidity
    ]

    Enum.reduce(fields, changeset, fn field, acc ->
      min = get_field(acc, :"min_#{field}")
      ideal = get_field(acc, :"ideal_#{field}")
      max = get_field(acc, :"max_#{field}")

      acc
      |> Map.update!(:errors, fn errs ->
        Enum.reject(errs, fn {key, _} ->
          key in [:"min_#{field}", :"ideal_#{field}", :"max_#{field}"]
        end)
      end)
      |> validate_order(:min, field, min, ideal, max)
    end)
  end

  def validate_order(changeset, _, field, nil, nil, nil), do: changeset

  def validate_order(changeset, _, field, min, ideal, max) do
    cond do
      min != nil and ideal != nil and min > ideal ->
        add_error(changeset, :"min_#{field}", "Não pode ser maior que o ideal")

      min != nil and max != nil and min > max ->
        add_error(changeset, :"min_#{field}", "Não pode ser maior que o máximo")

      ideal != nil and max != nil and ideal > max ->
        add_error(changeset, :"ideal_#{field}", "Não pode ser maior que o máximo")

      ideal != nil and min != nil and ideal < min ->
        add_error(changeset, :"ideal_#{field}", "Não pode ser menor que o mínimo")

      max != nil and ideal != nil and max < ideal ->
        add_error(changeset, :"max_#{field}", "Não pode ser menor que o ideal")

      max != nil and min != nil and max < min ->
        add_error(changeset, :"max_#{field}", "Não pode ser menor que o mínimo")

      true ->
        changeset
    end
  end
end
