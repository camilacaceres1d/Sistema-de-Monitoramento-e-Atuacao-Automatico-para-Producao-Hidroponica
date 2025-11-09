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
      where: s.active == true
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
    today in schedule.days_of_week and
      Time.compare(now, schedule.start_time) != :lt and
      Time.compare(now, schedule.end_time) == :lt
  end

  defp control_pump(%IrrigationSchedule{} = schedule, %Device{} = device, now) do
    seconds_since_start =
      Time.diff(now, schedule.start_time, :second)

    cycle_duration = schedule.on_seconds + schedule.off_seconds

    position_in_cycle = rem(seconds_since_start, cycle_duration)

    desired_state =
      if position_in_cycle < schedule.on_seconds do
        :on
      else
        :off
      end

    current_state = get_pump_state(device.id)

    if desired_state != current_state do
      device = Greenhouse.get_device_from_config(device.id)

      case desired_state do
        :on ->
          Greenhouse.set_pump_state(device, true)

        :off ->
          Greenhouse.set_pump_state(device, false)
      end
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
