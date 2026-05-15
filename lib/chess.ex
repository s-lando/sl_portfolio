defmodule Chess do
  @moduledoc """
  Public API for the Chess game logic.

  ## Example

      game = Chess.new_game()
      {:ok, game} = Chess.move(game, {4, 1}, {4, 3})  # e2-e4
      moves = Chess.legal_moves(game, {4, 6})          # e7 pawn options
  """

  alias Chess.{Board, Game}

  defdelegate new_game(), to: Game, as: :new
  defdelegate move(game, from, to), to: Game
  defdelegate legal_moves(game, from), to: Game

  @spec print(Game.t()) :: :ok
  def print(game) do
    IO.puts(Board.to_string(game.board))
    IO.puts("Turn: #{game.turn}  Status: #{game.status}")
  end
end
