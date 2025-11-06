defmodule SistemaControleWeb.Device.Index do
  use SistemaControleWeb, :live_view

  alias SistemaControle.Devices
  alias SistemaControle.Sensors
  alias SistemaControle.Greenhouse

  @impl true
  def mount(%{"id" => device_id}, _session, socket) do
    if connected?(socket) do
      Devices.subscribe(device_id)
    end

    device = Devices.get_device_by_id(device_id)
    pump_state = Sensors.get_last_pump_state(device_id)
    sensor_data = Sensors.get_sensor_data_by_device(device_id)
    greenhouse_config = Greenhouse.get_greenhouse_config(device_id)
    changeset = Greenhouse.change_greenhouse_config(greenhouse_config || %{})

    {:ok,
     socket
     |> stream(:sensor_data, sensor_data)
     |> assign(
       device: device,
       pump_state: pump_state,
       pump_loading: false,
       greenhouse_config: greenhouse_config,
       form: to_form(changeset, as: :config_form)
     )}
  end

  @impl true
  def handle_event("toggle_pump", %{"state" => state}, socket) do
    if socket.assigns.pump_loading do
      {:noreply, socket}
    else
      sendState =
        case state do
          "true" -> true
          "false" -> false
        end

      Devices.send_pump_command(socket.assigns.device.device_mac, sendState)
      {:noreply, socket |> assign(pump_loading: true)}
    end
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
         |> assign(form: to_form(changeset, as: :config_form))
         |> put_flash(:error, "Erro ao salvar configurações.")}
    end
  end

  @impl true
  def handle_info({:new_sensor_data, sensor_data}, socket) do
    loading = sensor_data.pump_state != socket.assigns.pump_state

    {:noreply,
     socket
     |> stream_insert(:sensor_data, sensor_data, at: 0)
     |> assign(pump_state: sensor_data.pump_state, pump_loading: loading)}
  end

  @impl true
  def handle_info({:device_updated, sensor_data}, socket) do
    {:noreply, socket |> assign(device: sensor_data)}
  end
end
