defmodule SistemaControle.Repo.Migrations.CreateGreenhouseTable do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :name, :string, null: true
      add :device_mac, :string, null: false
      add :type, :string, null: false

      add :greenhouse_id, references(:devices, on_delete: :nothing)

      timestamps()
    end

    alter table(:sensor_data) do
      add :device_id, references(:devices, on_delete: :nothing)
    end
  end
end
