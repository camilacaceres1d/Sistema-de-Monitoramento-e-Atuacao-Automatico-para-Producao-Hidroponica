defmodule SistemaControle.Workers.LightWorker do
  use Oban.Worker, queue: :light, max_attempts: 3
  import Ecto.Query, only: [from: 2]

  alias SistemaControle.{Repo, Greenhouse}
  alias SistemaControle.Schemas.{LightSchedule, Device}

  @impl Oban.Worker
  def perform(_job) do
    check_and_start_light()
    :ok
  end

  def check_and_start_light() do
    now = Time.utc_now() |> Time.truncate(:second)

    today =
      DateTime.now!("Etc/UTC")
      |> DateTime.shift_zone!("America/Sao_Paulo")
      |> DateTime.to_date()
      |> Date.day_of_week()

    from(s in LightSchedule,
      where: s.active == true and ^today in s.days_of_week
    )
    |> Repo.all()
    |> Enum.each(fn %LightSchedule{} = schedule ->
      device = Greenhouse.get_device_from_config(schedule.greenhouse_config_id)
      light_state = Greenhouse.get_light_state(device.id)

      if should_be_on?(schedule, now, today) do
        control_light(schedule, device, now)
      else
        if light_state do
          Greenhouse.toggle_lights(device.id, false)
        end
      end
    end)
  end

  defp should_be_on?(%LightSchedule{} = schedule, now, today) do
    start_time = schedule.start_time
    end_time = schedule.end_time

    in_time_window =
      cond do
        Time.compare(end_time, start_time) == :lt ->
          Time.compare(now, start_time) != :lt or Time.compare(now, end_time) == :lt

        true ->
          Time.compare(now, start_time) != :lt and Time.compare(now, end_time) == :lt
      end

    today in schedule.days_of_week and in_time_window
  end

  defp control_light(%LightSchedule{} = schedule, %Device{} = device, now) do
    seconds_since_start =
      case Time.compare(now, schedule.start_time) do
        :lt -> Time.diff(Time.add(now, 86_400, :second), schedule.start_time, :second)
        _ -> Time.diff(now, schedule.start_time, :second)
      end

    cycle_duration = schedule.on_seconds + schedule.off_seconds

    position_in_cycle =
      rem(seconds_since_start, cycle_duration)
      |> case do
        n when n < 0 -> n + cycle_duration
        n -> n
      end

    desired_state = if position_in_cycle < schedule.on_seconds, do: true, else: false

    current_state = Greenhouse.get_light_state(device.id)

    if desired_state != current_state do
      Greenhouse.toggle_lights(device.id, desired_state)
    end
  end
end
