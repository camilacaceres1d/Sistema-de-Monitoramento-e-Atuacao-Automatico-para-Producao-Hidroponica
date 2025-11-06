defmodule SistemaControleWeb.Dashboard.Index do
  use SistemaControleWeb, :live_view

  alias SistemaControle.Greenhouse

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Greenhouse.subscribe_all()
    end

    greenhouses =
      Greenhouse.get_all()
      |> Enum.map(fn item ->
        %{
          id: item.greenhouse.id,
          greenhouse: item.greenhouse,
          latest_sensor_data: item.latest_sensor_data
        }
      end)

    {:ok, socket |> stream(:greenhouses, greenhouses)}
  end

  @impl true
  def handle_info({:new_greenhouse, greenhouse}, socket) do
    {:noreply, socket |> stream_insert(:greenhouses, greenhouse, at: 0)}
  end

  @impl true
  def handle_info({:greenhouse_update, greenhouse}, socket) do
    {:noreply, socket |> stream_insert(:greenhouses, greenhouse, replace: true)}
  end
end
