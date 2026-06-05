defmodule SlPortfolio.Repo.Migrations.CreateChessGameState do
  use Ecto.Migration

  def change do
    create table(:chess_game_state) do
      add :state, :binary, null: false
      timestamps()
    end
  end
end
