defmodule SistemaControle.Repo.Migrations.ScheduleMinutes do
  use Ecto.Migration

  def change do
    alter table(:irrigation_schedules) do
      remove :on_seconds
      remove :off_seconds
      add :on_minutes, :integer, null: false, default: 0
      add :off_minutes, :integer, null: false, default: 0
    end

    alter table(:light_schedule) do
      remove :on_seconds
      remove :off_seconds
      add :on_minutes, :integer, null: false, default: 0
      add :off_minutes, :integer, null: false, default: 0
    end
  end
end
