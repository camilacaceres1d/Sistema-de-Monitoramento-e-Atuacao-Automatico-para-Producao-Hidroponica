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

    sensor_data = Sensors.get_sensor_data_by_device(device_id)

    {:ok, socket |> stream(:sensor_data, sensor_data) |> assign(device: device)}
  end

  @impl true
  def handle_info({:new_sensor_data, sensor_data}, socket) do
    {:noreply, socket |> stream_insert(:sensor_data, sensor_data, at: 0)}
  end

  @impl true
  def handle_info({:device_updated, sensor_data}, socket) do
    {:noreply, socket |> assign(device: sensor_data)}
  end
end
