defmodule SistemaControle.Devices do
  import Ecto.Query
  alias SistemaControle.Greenhouse
  alias SistemaControle.Schemas.Device
  alias SistemaControle.Repo

  @doc """
    Create a device entry
  """
  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
    Update a device entry
  """
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  @doc """
    Get a device by ID
  """
  def get_device_by_id(id) do
    Repo.get(Device, id)
  end

  @doc """
    Get a device by device MAC address
  """
  def get_device_by_mac(device_mac) do
    Repo.get_by(Device, device_mac: device_mac)
  end

  @doc """
    Create or update a device by device MAC address
  """
  def create_or_update_device(device_mac, type) do
    case get_device_by_mac(device_mac) do
      nil ->

        {:ok, device} =
          create_device(%{device_mac: device_mac, type: type})

        name =  case type do
          :greenhouse -> "Estufa #{device.id}"
          :bench -> "Bancada #{device.id}"
        end

        {:ok, device} = update_device(device, %{device_mac: device_mac, type: type, name: name})

        if type == :greenhouse do
          SistemaControle.Greenhouse.create_if_not_exists(device.id)
          Greenhouse.broadcast_new(device)
        end

        device

      device ->
        if type == :greenhouse do
          SistemaControle.Greenhouse.create_if_not_exists(device.id)
        end

        broadcast(device.id, {:device_updated, device})
        {:ok, device}
    end
  end

  @doc """
    Send a message to active a pump
  """
  def send_pump_command(device_mac, state) do
    SistemaControle.MqttClient.publish(
      "greenhouse/#{device_mac}/commands",
      Jason.encode!(%{atuador: "bomba", valor: state})
    )
  end

  @doc """
    Get available benchs to associate with a greenhouse
  """
  def get_available_benchs() do
    from(d in Device,
      where: d.type == :bench and is_nil(d.greenhouse_id)
    )
    |> Repo.all()
  end

  @doc """
    Subscribe to updates from a device
  """
  def subscribe(id) do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "device:#{id}")
  end

  def broadcast(id, message) do
    Phoenix.PubSub.broadcast(
      SistemaControle.PubSub,
      "device:#{id}",
      message
    )
  end

  @doc """
  Subscribe to all device messages
  """
  def subscribe_device_all do
    Phoenix.PubSub.subscribe(SistemaControle.PubSub, "devices:all")
  end

  def broadcast_device_all(message) do
    Phoenix.PubSub.broadcast(
      SistemaControle.PubSub,
      "devices:all",
      message
    )
  end
end
