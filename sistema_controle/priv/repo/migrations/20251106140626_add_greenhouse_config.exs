defmodule SistemaControle.Repo.Migrations.AddGreenhouseConfig do
  use Ecto.Migration

  def change do
    create table(:greenhouse_configs) do
      add :name, :string, null: false
      add :min_ph, :float, null: false
      add :ideal_ph, :float, null: false
      add :max_ph, :float, null: false
      add :min_ec, :float, null: false
      add :ideal_ec, :float, null: false
      add :max_ec, :float, null: false
      add :min_water_temp, :float, null: false
      add :ideal_water_temp, :float, null: false
      add :max_water_temp, :float, null: false
      add :min_air_temp, :float, null: false
      add :ideal_air_temp, :float, null: false
      add :max_air_temp, :float, null: false
      add :min_air_humidity, :float, null: false
      add :ideal_air_humidity, :float, null: false
      add :max_air_humidity, :float, null: false
      add :crop_name, :string, null: false

      add :device_id, references(:devices, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:greenhouse_configs, [:device_id])
  end
end
