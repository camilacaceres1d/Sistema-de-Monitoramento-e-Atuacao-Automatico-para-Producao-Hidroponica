defmodule SistemaControle.Schemas.IrrigationSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "irrigation_schedules" do
    field :start_time, :time
    field :end_time, :time
    field :on_seconds, :integer
    field :off_seconds, :integer
    field :days_of_week, {:array, :integer}, default: [0, 1, 2, 3, 4, 5, 6]
    field :active, :boolean, default: true

    belongs_to :greenhouse_config, SistemaControle.Schemas.GreenhouseConfig

    timestamps()
  end

  def changeset(irrigation_schedule, attrs) do
    irrigation_schedule
    |> cast(attrs, [
      :start_time,
      :end_time,
      :on_seconds,
      :off_seconds,
      :days_of_week,
      :active,
      :greenhouse_config_id
    ])
    |> validate_required([
      :start_time,
      :end_time,
      :on_seconds,
      :off_seconds,
      :greenhouse_config_id
    ])
  end
end
