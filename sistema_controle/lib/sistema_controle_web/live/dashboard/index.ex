defmodule SistemaControleWeb.Dashboard.Index do
  use SistemaControleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      SistemaControle.Devices.subscribe_device_all()
    end

    greenhouses = SistemaControle.Devices.get_all_greenhouses()

    IO.inspect(greenhouses, label: "Greenhouses")
    {:ok, socket |> stream(:greenhouses, greenhouses)}
  end

  @impl true
  def handle_info({:new_device, greenhouse}, socket) do
    {:noreply, socket |> stream_insert(:greenhouses, greenhouse, at: 0)}
  end
end
