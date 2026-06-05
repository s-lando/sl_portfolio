defmodule SlPortfolio.Chess.GameState do
  use Ecto.Schema

  schema "chess_game_state" do
    field :state, :binary
    timestamps()
  end
end
