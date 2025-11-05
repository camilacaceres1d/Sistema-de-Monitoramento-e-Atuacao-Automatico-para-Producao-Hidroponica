defmodule SistemaControle.Repo do
  use Ecto.Repo,
    otp_app: :sistema_controle,
    adapter: Ecto.Adapters.Postgres
end
