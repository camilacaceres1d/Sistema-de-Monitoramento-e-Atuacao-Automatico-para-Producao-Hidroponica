defmodule SistemaControleWeb.Dashboard.Index do
  use SistemaControleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      SistemaControle.Sensors.subscribe_all()
    end

    sensor_data = SistemaControle.Sensors.get_all_sensor_data()
    {:ok, socket |> stream(:sensor_data, sensor_data)}
  end

  @impl true
  def handle_info({:new_sensor_data, sensor_data}, socket) do
    {:noreply, socket |> stream_insert(:sensor_data, sensor_data, at: 0)}
  end
end
