defmodule SistemaControle.Irrigation do
  import Ecto.Query
  alias SistemaControle.Schemas.IrrigationSchedule
  alias SistemaControle.Repo

  def change_irrigation_schedule(%IrrigationSchedule{} = irrigation_schedule, attrs \\ %{}) do
    IrrigationSchedule.changeset(irrigation_schedule, attrs)
  end

  @doc """
    Create irrigation schedule for greenhouse
  """
  def create_irrigation_schedule(attrs \\ %{}) do
    %IrrigationSchedule{}
    |> IrrigationSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Update irrigation schedule
  """
  def update(%IrrigationSchedule{} = irrigation_schedule, attrs) do
    irrigation_schedule
    |> change_irrigation_schedule(attrs)
    |> Repo.update()
  end

  @doc """
    Toggle irrgation schedule active status
  """
  def toggle_irrigation_schedule_active(id) do
    irrigation_schedule = get_irrigation_schedule(id)

    case irrigation_schedule do
      nil ->
        {:error, :not_found}

      _ ->
        new_status = !irrigation_schedule.active

        irrigation_schedule
        |> change_irrigation_schedule(%{active: new_status})
        |> Repo.update()
    end
  end

  @doc """
    Get irrigation schedule by ID
  """
  def get_irrigation_schedule(id) do
    Repo.get(IrrigationSchedule, id)
  end

  @doc """
    Get irrigation schedules by greenhouse config ID
  """
  def get_irrigation_schedules(greenhouse_config_id) do
    Repo.all(
      from(is in IrrigationSchedule,
        where: is.greenhouse_config_id == ^greenhouse_config_id
      )
    )
  end
end
