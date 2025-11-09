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
    attrs =
      attrs
      |> Map.put("start_time", to_utc(Map.get(attrs, "start_time_input")))
      |> Map.put("end_time", to_utc(Map.get(attrs, "end_time_input")))

    %IrrigationSchedule{}
    |> IrrigationSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Update irrigation schedule
  """
  def update(%IrrigationSchedule{} = irrigation_schedule, attrs) do
    attrs =
      attrs
      |> Map.put("start_time", to_utc(Map.get(attrs, "start_time_input")))
      |> Map.put("end_time", to_utc(Map.get(attrs, "end_time_input")))

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
        |> IrrigationSchedule.changeset_toggle(%{active: new_status})
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

  def to_utc(nil), do: nil

  def to_utc(%Time{} = time) do
    shift_time(time, -3)
  end

  def to_utc(str) when is_binary(str) do
    str =
      case String.split(str, ":") do
        [h, m] -> "#{h}:#{m}:00"
        _ -> str
      end

    case Time.from_iso8601(str) do
      {:ok, time} -> shift_time(time, -3)
      _ -> nil
    end
  end

  defp shift_time(time, offset_hours) do
    total_seconds = time.hour * 3600 + time.minute * 60 + time.second
    utc_seconds = rem(total_seconds - offset_hours * 3600 + 24 * 3600, 24 * 3600)

    %Time{
      hour: div(utc_seconds, 3600),
      minute: div(rem(utc_seconds, 3600), 60),
      second: rem(utc_seconds, 60)
    }
  end
end
