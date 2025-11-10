defmodule SistemaControle.Repo.Migrations.LightSchedule do
  use Ecto.Migration

  def change do
    create table(:light_schedule) do
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :on_seconds, :integer, null: false
      add :off_seconds, :integer, null: false
      add :days_of_week, {:array, :integer}, default: [0, 1, 2, 3, 4, 5, 6], null: false
      add :active, :boolean, default: true, null: false

      add :greenhouse_config_id, references(:greenhouse_configs, on_delete: :delete_all),
        null: false

      timestamps()
    end
  end
end
