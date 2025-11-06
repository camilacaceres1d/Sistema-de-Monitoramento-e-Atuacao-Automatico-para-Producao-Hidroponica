defmodule SistemaControleWeb.Device.Index do
  use SistemaControleWeb, :live_view

  alias SistemaControle.Devices
  alias SistemaControle.Sensors

  @impl true
  def mount(%{"id" => device_id}, _session, socket) do
    if connected?(socket) do
      Devices.subscribe(device_id)
    end

    device = Devices.get_device_by_id(device_id)
    pump_state = Sensors.get_last_pump_state(device_id)
    sensor_data = Sensors.get_sensor_data_by_device(device_id)

    {:ok,
     socket
     |> stream(:sensor_data, sensor_data)
     |> assign(device: device, pump_state: pump_state, pump_loading: false)}
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
