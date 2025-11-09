defmodule SistemaControleWeb.Device.Index do
  use SistemaControleWeb, :live_view

  alias SistemaControle.Devices
  alias SistemaControle.Sensors
  alias SistemaControle.Greenhouse
  alias SistemaControle.Irrigation
  alias SistemaControle.Schemas.IrrigationSchedule

  @impl true
  def mount(%{"id" => device_id}, _session, socket) do
    if connected?(socket) do
      Devices.subscribe(device_id)
    end

    device = Devices.get_device_by_id(device_id)
    pump_state = Sensors.get_last_pump_state(device_id)
    greenhouse_config = Greenhouse.get_greenhouse_config(device_id)
    associated_benchs = Greenhouse.get_associated_benchs(device_id)
    sensor_data = Greenhouse.get_all_sensor_data(device_id)
    changeset = Greenhouse.change_greenhouse_config(greenhouse_config || %{})
    available_benchs = Devices.get_available_benchs()

    irrigation_schedules =
      if greenhouse_config do
        Irrigation.get_irrigation_schedules(greenhouse_config.id)
      else
        []
      end

    changeset_irrigation_schedule =
      SistemaControle.Irrigation.change_irrigation_schedule(
        %SistemaControle.Schemas.IrrigationSchedule{}
      )

    {:ok,
     socket
     |> stream(:sensor_data, sensor_data)
     |> assign(
       device: device,
       pump_state: pump_state,
       greenhouse_config: greenhouse_config,
       form_config: to_form(changeset, as: :config_form),
       irrigation_schedules: irrigation_schedules,
       irrigation_schedule_form:
         to_form(changeset_irrigation_schedule, as: :irrigation_schedule_form),
       is_edit: false,
       id_edit: nil,
       available_benchs: available_benchs,
       associated_benchs: associated_benchs,
       form_add_bench: to_form(%{"bench_id" => nil}, as: :form_add_bench),
       open_config_form: nil,
       sensor_data: sensor_data
     )
     |> push_charts(sensor_data)}
  end

  @impl true
  def handle_event("open_config_form", %{"form" => form}, socket) do
    {:noreply,
     socket
     |> assign(
       open_config_form:
         if socket.assigns.open_config_form == String.to_atom(form) do
           nil
         else
           String.to_atom(form)
         end
     )}
  end

  @impl true
  def handle_event("toggle_pump", %{"state" => state}, socket) do
    sendState =
      case state do
        "true" -> true
        "false" -> false
      end

    Devices.send_pump_command(socket.assigns.device.device_mac, sendState)
    {:noreply, socket}
  end

  def handle_event("save_config", %{"config_form" => config_params}, socket) do
    case Greenhouse.update(
           socket.assigns.greenhouse_config,
           config_params
         ) do
      {:ok, updated_config} ->
        {:noreply,
         socket
         |> assign(greenhouse_config: updated_config)
         |> put_flash(:info, "Configurações salvas com sucesso.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form_config: to_form(changeset, as: :config_form))
         |> put_flash(:error, "Erro ao salvar configurações.")}
    end
  end

  def handle_event(
        "validate_irrigation_schedule",
        %{"irrigation_schedule_form" => schedule_params},
        socket
      ) do
    attrs =
      Map.put(schedule_params, "greenhouse_config_id", socket.assigns.greenhouse_config.id)
      |> normalize_days()

    changeset =
      %IrrigationSchedule{}
      |> IrrigationSchedule.changeset(attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket |> assign(irrigation_schedule_form: to_form(changeset, as: :irrigation_schedule_form))}
  end

  def handle_event(
        "add_irrigation_schedule",
        %{"irrigation_schedule_form" => schedule_params},
        socket
      ) do
    attrs =
      Map.put(schedule_params, "greenhouse_config_id", socket.assigns.greenhouse_config.id)
      |> normalize_days()

    case Irrigation.create_irrigation_schedule(attrs) do
      {:ok, _schedule} ->
        refresh_schedules(socket, "Cronograma de irrigação adicionado com sucesso")

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(
           irrigation_schedule_form: to_form(changeset, as: :irrigation_schedule_form),
           is_edit: false
         )
         |> put_flash(:error, "Erro ao adicionar cronograma de irrigação.")}
    end
  end

  def handle_event(
        "edit_irrigation_schedule",
        %{"irrigation_schedule_form" => schedule_params},
        socket
      ) do
    schedule = Irrigation.get_irrigation_schedule(socket.assigns.id_edit)

    attrs = normalize_days(schedule_params)

    case Irrigation.update(schedule, attrs) do
      {:ok, _schedule} ->
        refresh_schedules(socket, "Cronograma de irrigação atualizado com sucesso")

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(
           irrigation_schedule_form: to_form(changeset, as: :irrigation_schedule_form),
           is_edit: true
         )
         |> put_flash(:error, "Erro ao atualizar cronograma de irrigação.")}
    end
  end

  def handle_event("toggle_irrigation_schedule", %{"id" => schedule_id}, socket) do
    case Irrigation.toggle_irrigation_schedule_active(schedule_id) do
      {:ok, _schedule} ->
        updated_schedules =
          Irrigation.get_irrigation_schedules(socket.assigns.greenhouse_config.id)

        {:noreply,
         socket
         |> assign(irrigation_schedules: updated_schedules)
         |> put_flash(:info, "Cronograma de irrigação atualizado com sucesso.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Erro ao atualizar cronograma de irrigação.")}
    end
  end

  def handle_event("open_edit_irrigation_schedule", %{"id" => schedule_id}, socket) do
    schedule = Irrigation.get_irrigation_schedule(schedule_id)

    changeset = Irrigation.change_irrigation_schedule(schedule)

    days_of_week_options =
      Enum.map(schedule.days_of_week, fn day ->
        Integer.to_string(day)
      end)

    changeset =
      changeset
      |> Ecto.Changeset.put_change(:days_of_week, days_of_week_options)
      |> Ecto.Changeset.put_change(:start_time_input, from_utc(schedule.start_time))
      |> Ecto.Changeset.put_change(:end_time_input, from_utc(schedule.end_time))

    {:noreply,
     socket
     |> assign(
       irrigation_schedule_form: to_form(changeset, as: :irrigation_schedule_form),
       is_edit: true,
       id_edit: schedule_id
     )}
  end

  def handle_event("add_bench", %{"form_add_bench" => %{"bench_id" => bench_id}}, socket) do
    Greenhouse.link_bench(socket.assigns.device.id, bench_id)

    {:noreply,
     socket
     |> assign(
       associated_benchs: Greenhouse.get_associated_benchs(socket.assigns.device.id),
       available_benchs: Devices.get_available_benchs()
     )}
  end

  def handle_event("remove_bench", %{"bench_id" => bench_id}, socket) do
    case Greenhouse.unlink_bench(bench_id) do
      {:ok, _bench} ->
        {:noreply,
         socket
         |> assign(
           associated_benchs: Greenhouse.get_associated_benchs(socket.assigns.device.id),
           available_benchs: Devices.get_available_benchs()
         )
         |> put_flash(:info, "Bancada desvinculada com sucesso.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Erro ao desvincular bancada.")}
    end
  end

  @impl true
  def handle_info({:new_sensor_data, sensor_data}, socket) do
    new_pump_state =
      if sensor_data.pump_state != nil,
        do: sensor_data.pump_state,
        else: socket.assigns.pump_state

    updated_data =
      case socket.assigns.sensor_data do
        [] ->
          [
            %{
              inserted_at: sensor_data.inserted_at,
              ph: sensor_data.ph,
              ec: sensor_data.ec,
              water_temperature: sensor_data.water_temperature,
              air_temperature: sensor_data.air_temperature,
              air_humidity: sensor_data.air_humidity,
              water_flow: sensor_data.water_flow
            }
          ]

        existing_data ->
          last_records = List.first(existing_data)

          merged_record = %{
            inserted_at: sensor_data.inserted_at,
            ph: sensor_data.ph || last_records.ph,
            ec: sensor_data.ec || last_records.ec,
            water_temperature: sensor_data.water_temperature || last_records.water_temperature,
            air_temperature: sensor_data.air_temperature || last_records.air_temperature,
            air_humidity: sensor_data.air_humidity || last_records.air_humidity,
            water_flow: sensor_data.water_flow || last_records.water_flow
          }

          [merged_record | existing_data]
          |> Enum.take(100)
      end

    {:noreply,
     socket
     |> assign(sensor_data: updated_data, pump_state: new_pump_state)
     |> stream_insert(:sensor_data, sensor_data, at: 0)
     |> push_charts(updated_data)}
  end

  @impl true
  def handle_info({:device_updated, sensor_data}, socket) do
    {:noreply, socket |> assign(device: sensor_data)}
  end

  defp normalize_days(attrs) do
    case Map.get(attrs, "days_of_week") do
      nil ->
        attrs

      days when is_list(days) ->
        Map.put(attrs, "days_of_week", Enum.map(days, &String.to_integer/1))

      day when is_binary(day) ->
        Map.put(attrs, "days_of_week", [String.to_integer(day)])

      _ ->
        attrs
    end
  end

  def refresh_schedules(socket, msg) do
    updated_schedules =
      Irrigation.get_irrigation_schedules(socket.assigns.greenhouse_config.id)

    {:noreply,
     socket
     |> assign(
       irrigation_schedules: updated_schedules,
       irrigation_schedule_form:
         to_form(Irrigation.change_irrigation_schedule(%IrrigationSchedule{}),
           as: :irrigation_schedule_form
         ),
       is_edit: false
     )
     |> put_flash(:info, msg)}
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

  defp push_charts(socket, sensor_data) do
    datasets = %{
      "pH" =>
        sensor_data
        |> Enum.filter(& &1.ph)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.ph} end),
      "EC" =>
        sensor_data
        |> Enum.filter(& &1.ec)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.ec} end),
      "Temperatura da Água" =>
        sensor_data
        |> Enum.filter(& &1.water_temperature)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.water_temperature} end),
      "Temperatura do Ar" =>
        sensor_data
        |> Enum.filter(& &1.air_temperature)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.air_temperature} end),
      "Umidade do Ar" =>
        sensor_data
        |> Enum.filter(& &1.air_humidity)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.air_humidity} end),
      "Fluxo de água" =>
        sensor_data
        |> Enum.filter(& &1.water_flow)
        |> Enum.map(fn r -> %{x: r.inserted_at, y: r.water_flow} end)
    }

    Enum.reduce(datasets, socket, fn {key, data}, sock ->
      opts = build_chart_options(key, data)
      push_event(sock, "chart-update-#{key}", opts)
    end)
  end

  defp format_datetime_br(naive_datetime) do
    day = naive_datetime.day |> Integer.to_string() |> String.pad_leading(2, "0")
    month = naive_datetime.month |> Integer.to_string() |> String.pad_leading(2, "0")
    hour = naive_datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")
    minute = naive_datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0")
    second = naive_datetime.second |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{day}/#{month} #{hour}:#{minute}:#{second}"
  end

  defp build_chart_options(name, data) do
    cleaned_data =
      data
      |> Enum.reject(&is_nil(&1.y))
      |> Enum.sort_by(& &1.x)

    %{
      tooltip: %{
        trigger: "axis",
        formatter:
          "function(params) { if (!params || params.length === 0) return ''; const date = params[0].name; const value = params[0].value; return date + '<br/>' + params[0].seriesName + ': ' + value; }"
      },
      xAxis: %{
        type: "category",
        boundaryGap: false,
        data: Enum.map(cleaned_data, &format_datetime_br(&1.x)),
        axisLabel: %{rotate: 45, fontSize: 10}
      },
      yAxis: %{type: "value", name: name},
      grid: %{left: "10%", right: "5%", bottom: "40", top: "15%", containLabel: true},
      series: [
        %{
          name: name,
          type: "line",
          data: Enum.map(cleaned_data, & &1.y),
          smooth: true,
          symbol: "circle",
          symbolSize: 4,
          lineStyle: %{width: 2},
          animation: true,
          animationDuration: 300
        }
      ]
    }
  end
end
