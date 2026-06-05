defmodule SlPortfolio.Repo do
  use Ecto.Repo,
    otp_app: :sl_portfolio,
    adapter: Ecto.Adapters.Postgres
end
