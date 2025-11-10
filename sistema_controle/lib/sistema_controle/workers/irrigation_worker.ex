defmodule SistemaControle.Workers.IrrigationWorker do
  use Oban.Worker, queue: :irrigation, max_attempts: 3
  import Ecto.Query, only: [from: 2]

  alias SistemaControle.{Repo, Greenhouse}
  alias SistemaControle.Schemas.{IrrigationSchedule, SensorData, Device}

  @impl Oban.Worker
  def perform(_job) do
    check_and_start_irrigation()
    :ok
  end

  def check_and_start_irrigation() do
    now = Time.utc_now() |> Time.truncate(:second)

    today =
      DateTime.now!("Etc/UTC")
      |> DateTime.shift_zone!("America/Sao_Paulo")
      |> DateTime.to_date()
      |> Date.day_of_week()

    from(s in IrrigationSchedule,
      where: s.active == true and ^today in s.days_of_week
    )
    |> Repo.all()
    |> Enum.each(fn %IrrigationSchedule{} = schedule ->
      device = Greenhouse.get_device_from_config(schedule.greenhouse_config_id)
      pump_state = get_pump_state(device.id)

      if should_be_on?(schedule, now, today) do
        control_pump(schedule, device, now)
      else
        if pump_state == :on do
          Greenhouse.set_pump_state(device, false)
        end
      end
    end)
  end

  defp should_be_on?(%IrrigationSchedule{} = schedule, now, today) do
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

  defp control_pump(%IrrigationSchedule{} = schedule, %Device{} = device, now) do
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

    desired_state = if position_in_cycle < schedule.on_seconds, do: :on, else: :off

    current_state = get_pump_state(device.id)

    if desired_state != current_state do
      Greenhouse.set_pump_state(device, desired_state == :on)
    end
  end

  defp get_pump_state(device_id) do
    from(sd in SensorData,
      where: sd.device_id == ^device_id,
      order_by: [desc: sd.inserted_at],
      limit: 1,
      select: sd.pump_state
    )
    |> Repo.one()
    |> case do
      true ->
        :on

      false ->
        :off

      nil ->
        :on
    end
  end
end
