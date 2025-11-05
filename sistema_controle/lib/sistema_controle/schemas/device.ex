defmodule SistemaControle.Schemas.Device do
  use Ecto.Schema

  import Ecto.Changeset

  schema "devices" do
    field :name, :string
    field :device_mac, :string
    field :type, Ecto.Enum, values: [:greenhouse, :bench]

    field :greenhouse_id, :id

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [
      :name,
      :device_mac,
      :type,
      :greenhouse_id
    ])
    |> validate_required([:device_mac, :type])
  end
end
