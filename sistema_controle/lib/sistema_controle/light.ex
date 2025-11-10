defmodule SistemaControle.Light do
  import Ecto.Query
  alias SistemaControle.Schemas.LightSchedule
  alias SistemaControle.Repo

  def change_light_schedule(%LightSchedule{} = light_schedule, attrs \\ %{}) do
    LightSchedule.changeset(light_schedule, attrs)
  end

  @doc """
    Create light schedule for greenhouse
  """
  def create_light_schedule(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("start_time", to_utc(Map.get(attrs, "start_time_input")))
      |> Map.put("end_time", to_utc(Map.get(attrs, "end_time_input")))

    %LightSchedule{}
    |> LightSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Update light schedule
  """
  def update(%LightSchedule{} = light_schedule, attrs) do
    attrs =
      attrs
      |> Map.put("start_time", to_utc(Map.get(attrs, "start_time_input")))
      |> Map.put("end_time", to_utc(Map.get(attrs, "end_time_input")))

    light_schedule
    |> change_light_schedule(attrs)
    |> Repo.update()
  end

  @doc """
    Toggle light schedule active status
  """
  def toggle_light_schedule_active(id) do
    light_schedule = get_light_schedule(id)

    case light_schedule do
      nil ->
        {:error, :not_found}

      _ ->
        new_status = !light_schedule.active

        light_schedule
        |> LightSchedule.changeset_toggle(%{active: new_status})
        |> Repo.update()
    end
  end

  @doc """
    Get light schedule by ID
  """
  def get_light_schedule(id) do
    Repo.get(LightSchedule, id)
  end

  @doc """
    Get light schedules by greenhouse config ID
  """
  def get_light_schedules(greenhouse_config_id) do
    Repo.all(
      from(is in LightSchedule,
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
