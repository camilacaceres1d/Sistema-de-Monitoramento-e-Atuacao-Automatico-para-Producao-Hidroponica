defmodule SistemaControle.Schemas.LightSchedule do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias SistemaControle.Repo

  schema "light_schedule" do
    field(:start_time, :time)
    field(:end_time, :time)
    field(:on_minutes, :integer)
    field(:off_minutes, :integer)
    field(:days_of_week, {:array, :integer}, default: [1, 2, 3, 4, 5, 6, 7])
    field(:active, :boolean, default: true)
    field(:start_time_input, :time, virtual: true)
    field(:end_time_input, :time, virtual: true)

    belongs_to(:greenhouse_config, SistemaControle.Schemas.GreenhouseConfig)

    timestamps()
  end

  def changeset_toggle(schedule, attrs) do
    schedule
    |> cast(attrs, [
      :active
    ])
    |> validate_required([:active])
  end

  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [
      :start_time,
      :end_time,
      :start_time_input,
      :end_time_input,
      :on_minutes,
      :off_minutes,
      :days_of_week,
      :active,
      :greenhouse_config_id,
      :id
    ])
    |> validate_required(:start_time_input, message: "Hora de início é obrigatória")
    |> validate_required(:end_time_input, message: "Hora de fim é obrigatória")
    |> validate_required(:on_minutes, message: "Tempo ligado é obrigatório")
    |> validate_required(:off_minutes, message: "Tempo desligado é obrigatório")
    |> validate_days_of_week()
    |> validate_start_end()
    |> validate_required([:greenhouse_config_id])
    |> validate_overlapping_hours()
  end

  def validate_start_end(changeset) do
    start_time = get_field(changeset, :start_time_input)
    end_time = get_field(changeset, :end_time_input)

    if start_time && end_time do
      case Time.compare(start_time, end_time) do
        :gt ->
          add_error(
            changeset,
            :start_time_input,
            "Horário de início deve ser antes do horário de fim"
          )

        :eq ->
          add_error(
            changeset,
            :start_time_input,
            "Horário de início deve ser diferente do horário de fim"
          )

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  def validate_days_of_week(changeset) do
    days = get_field(changeset, :days_of_week, [])

    cond do
      not is_list(days) ->
        add_error(changeset, :days_of_week, "Deve ser uma lista de dias válidos")

      Enum.empty?(days) ->
        add_error(changeset, :days_of_week, "Selecione pelo menos um dia da semana")

      Enum.any?(days, fn day -> day < 1 or day > 7 end) ->
        add_error(
          changeset,
          :days_of_week,
          "Dias da semana devem estar entre 0 (domingo) e 6 (sábado)"
        )

      true ->
        changeset
    end
  end

  def validate_overlapping_hours(changeset) do
    greenhouse_config_id = get_field(changeset, :greenhouse_config_id)
    days_of_week = get_field(changeset, :days_of_week, [])
    current_id = get_field(changeset, :id)
    start_time = get_field(changeset, :start_time_input)
    end_time = get_field(changeset, :end_time_input)

    if greenhouse_config_id && start_time && end_time && days_of_week != [] do
      base_query =
        from(s in __MODULE__,
          where: s.greenhouse_config_id == ^greenhouse_config_id and s.active == true,
          select: %{
            id: s.id,
            start_time: s.start_time,
            end_time: s.end_time,
            days_of_week: s.days_of_week
          }
        )

      query =
        if current_id do
          from(s in base_query, where: s.id != ^current_id)
        else
          base_query
        end

      existing_schedules = Repo.all(query)

      overlapping? =
        Enum.any?(existing_schedules, fn schedule ->
          same_day? = Enum.any?(schedule.days_of_week, &(&1 in days_of_week))

          overlap? =
            Time.compare(start_time, from_utc(schedule.end_time)) == :lt and
              Time.compare(end_time, from_utc(schedule.start_time)) == :gt

          same_day? and overlap?
        end)

      if overlapping? do
        add_error(
          changeset,
          :start_time_input,
          "Já existe um cronograma com horário sobreposto para esta estufa"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  def from_utc(%Time{} = time) do
    total_seconds = time.hour * 3600 + time.minute * 60 + time.second
    local_seconds = rem(total_seconds - 3 * 3600 + 24 * 3600, 24 * 3600)

    %Time{
      hour: div(local_seconds, 3600),
      minute: div(rem(local_seconds, 3600), 60),
      second: rem(local_seconds, 60)
    }
  end

  def from_utc(%NaiveDateTime{} = time) do
    total_seconds = time.hour * 3600 + time.minute * 60 + time.second
    local_seconds = rem(total_seconds - 3 * 3600 + 24 * 3600, 24 * 3600)

    %NaiveDateTime{
      day: time.day,
      year: time.year,
      month: time.month,
      hour: div(local_seconds, 3600),
      minute: div(rem(local_seconds, 3600), 60),
      second: rem(local_seconds, 60)
    }
  end
end
