defmodule SistemaControle.Repo.Migrations.CreateSensorData do
  use Ecto.Migration

  def change do
    create table(:sensor_data) do
      add :ph, :float, null: true
      add :ec, :float, null: true
      add :water_temperature, :float, null: true
      add :air_temperature, :float, null: true
      add :air_humidity, :float, null: true
      add :water_flow, :float, null: true
      add :level0, :boolean, null: true
      add :level1, :boolean, null: true
      add :level2, :boolean, null: true
      add :pump_state, :boolean, null: true

      timestamps()
    end
  end
end
