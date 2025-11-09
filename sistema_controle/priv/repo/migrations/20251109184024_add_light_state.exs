defmodule SistemaControle.Repo.Migrations.AddLightState do
  use Ecto.Migration

  def change do
    alter table(:sensor_data) do
      add :light_state, :boolean, null: true
    end
  end
end
