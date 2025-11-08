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
       open_config_form: nil
     )}
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
         |> assign(irrigation_schedule_form: to_form(changeset, as: :irrigation_schedule_form))
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
        refresh_schedules(socket, "Cronograma de irrigação atualizado com sucesso", false)

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

    changeset = Ecto.Changeset.put_change(changeset, :days_of_week, days_of_week_options)

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
      if sensor_data.pump_state != nil do
        sensor_data.pump_state
      else
        socket.assigns.pump_state
      end

    {:noreply,
     socket
     |> stream_insert(:sensor_data, sensor_data, at: 0)
     |> assign(pump_state: new_pump_state)}
  end

  @impl true
  def handle_info({:device_updated, sensor_data}, socket) do
    {:noreply, socket |> assign(device: sensor_data)}
  end

  def normalize_days(attrs) do
    case Map.get(attrs, "days_of_week") do
      nil ->
        attrs

      options ->
        days = options |> Enum.at(0)
        days_of_week = Enum.map(days, fn day -> String.to_integer(day) end)
        Map.put(attrs, "days_of_week", days_of_week)
    end
  end

  def refresh_schedules(socket, msg, is_edit \\ true) do
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
       is_edit: is_edit
     )
     |> put_flash(:info, msg)}
  end
end
