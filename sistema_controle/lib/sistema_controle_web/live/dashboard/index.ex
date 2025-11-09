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
          latest_sensor_data: item.latest_sensor_data,
          avg_air_temp: item.avg_air_temp,
          avg_air_humidity: item.avg_air_humidity,
          avg_water_flow: item.avg_water_flow
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

  defp get_status_class(nil, _min, _ideal, _max), do: "bg-gray-100 text-gray-600"

  defp get_status_class(value, min, ideal, max) do
    tolerance = (max - min) * 0.15
    ideal_range = ideal * 0.10

    cond do
      value < min or value > max ->
        "bg-red-100 text-red-800 border border-red-300"

      value < min + tolerance or value > max - tolerance ->
        "bg-yellow-100 text-yellow-800 border border-yellow-300"

      value >= ideal - ideal_range and value <= ideal + ideal_range ->
        "bg-green-100 text-green-800 border border-green-300"

      true ->
        "bg-blue-50 text-blue-700 border border-blue-200"
    end
  end

  defp format_value(nil), do: "-"
  defp format_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 1)
  defp format_value(value), do: value
end
