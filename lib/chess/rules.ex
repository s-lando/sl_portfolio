defmodule Chess.Rules do
  @moduledoc false

  alias Chess.{Board, Piece}

  @type square :: Board.square()

  # Returns all pseudo-legal destination squares for the piece at `from`.
  # Does NOT filter moves that leave the king in check — call legal_moves/3 for that.
  @spec pseudo_legal_moves(Board.t(), square(), keyword()) :: [square()]
  def pseudo_legal_moves(board, from, opts \\ []) do
    en_passant = Keyword.get(opts, :en_passant)

    case Board.get(board, from) do
      nil -> []
      piece -> moves_for(piece, board, from, en_passant)
    end
  end

  # Returns only moves that do not leave the moving side's king in check.
  @spec legal_moves(Board.t(), square(), keyword()) :: [square()]
  def legal_moves(board, from, opts \\ []) do
    castling = Keyword.get(opts, :castling, %{})
    en_passant = Keyword.get(opts, :en_passant)

    case Board.get(board, from) do
      nil ->
        []

      piece ->
        base = moves_for(piece, board, from, en_passant)
        castle_moves = if piece.kind == :king, do: castle_destinations(board, piece.color, castling), else: []

        (base ++ castle_moves)
        |> Enum.filter(fn to ->
          new_board = apply_move(board, from, to, en_passant)
          not in_check?(new_board, piece.color)
        end)
    end
  end

  @spec in_check?(Board.t(), Piece.color()) :: boolean()
  def in_check?(board, color) do
    king_sq = find_king(board, color)
    attacked_by_any?(board, king_sq, Piece.opponent(color))
  end

  @spec checkmate?(Board.t(), Piece.color(), keyword()) :: boolean()
  def checkmate?(board, color, opts \\ []) do
    in_check?(board, color) and no_legal_moves?(board, color, opts)
  end

  @spec stalemate?(Board.t(), Piece.color(), keyword()) :: boolean()
  def stalemate?(board, color, opts \\ []) do
    not in_check?(board, color) and no_legal_moves?(board, color, opts)
  end

  # Applies a move for legality-testing purposes, handling en passant capture.
  @spec apply_move(Board.t(), square(), square(), square() | nil) :: Board.t()
  def apply_move(board, from, to, en_passant \\ nil) do
    piece = Board.get(board, from)
    board = Board.move(board, from, to)

    # En passant: remove the captured pawn
    if piece.kind == :pawn and to == en_passant do
      capture_row = if piece.color == :white, do: elem(to, 1) - 1, else: elem(to, 1) + 1
      Board.delete(board, {elem(to, 0), capture_row})
    else
      board
    end
  end

  # --- private ---

  defp moves_for(%Piece{kind: :pawn, color: color}, board, from, en_passant) do
    pawn_moves(board, from, color, en_passant)
  end

  defp moves_for(%Piece{kind: :knight, color: color}, board, from, _ep) do
    {col, row} = from

    [{2, 1}, {2, -1}, {-2, 1}, {-2, -1}, {1, 2}, {1, -2}, {-1, 2}, {-1, -2}]
    |> Enum.map(fn {dc, dr} -> {col + dc, row + dr} end)
    |> Enum.filter(&Board.in_bounds?/1)
    |> Enum.reject(fn sq -> friendly?(board, sq, color) end)
  end

  defp moves_for(%Piece{kind: :bishop, color: color}, board, from, _ep) do
    slide(board, from, color, [{1, 1}, {1, -1}, {-1, 1}, {-1, -1}])
  end

  defp moves_for(%Piece{kind: :rook, color: color}, board, from, _ep) do
    slide(board, from, color, [{1, 0}, {-1, 0}, {0, 1}, {0, -1}])
  end

  defp moves_for(%Piece{kind: :queen, color: color}, board, from, _ep) do
    slide(board, from, color, [
      {1, 0}, {-1, 0}, {0, 1}, {0, -1},
      {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    ])
  end

  defp moves_for(%Piece{kind: :king, color: color}, board, from, _ep) do
    {col, row} = from

    [{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}]
    |> Enum.map(fn {dc, dr} -> {col + dc, row + dr} end)
    |> Enum.filter(&Board.in_bounds?/1)
    |> Enum.reject(fn sq -> friendly?(board, sq, color) end)
  end

  defp pawn_moves(board, {col, row}, color, en_passant) do
    {dir, start_row} = if color == :white, do: {1, 1}, else: {-1, 6}

    one_step = {col, row + dir}
    two_step = {col, row + 2 * dir}

    advance =
      if Board.in_bounds?(one_step) and is_nil(Board.get(board, one_step)) do
        steps = [one_step]

        if row == start_row and is_nil(Board.get(board, two_step)),
          do: steps ++ [two_step],
          else: steps
      else
        []
      end

    captures =
      [{col - 1, row + dir}, {col + 1, row + dir}]
      |> Enum.filter(&Board.in_bounds?/1)
      |> Enum.filter(fn sq ->
        enemy?(board, sq, color) or sq == en_passant
      end)

    advance ++ captures
  end

  defp slide(board, {col, row}, color, directions) do
    Enum.flat_map(directions, fn {dc, dr} ->
      Stream.iterate(1, &(&1 + 1))
      |> Enum.reduce_while([], fn n, acc ->
        sq = {col + dc * n, row + dr * n}

        cond do
          not Board.in_bounds?(sq) -> {:halt, acc}
          friendly?(board, sq, color) -> {:halt, acc}
          enemy?(board, sq, color) -> {:halt, acc ++ [sq]}
          true -> {:cont, acc ++ [sq]}
        end
      end)
    end)
  end

  defp castle_destinations(board, color, castling) do
    row = if color == :white, do: 0, else: 7
    king_sq = {4, row}

    []
    |> maybe_add_castle(board, color, castling, king_sq, :kingside, {6, row}, [{5, row}, {6, row}])
    |> maybe_add_castle(board, color, castling, king_sq, :queenside, {2, row}, [{3, row}, {2, row}, {1, row}])
  end

  defp maybe_add_castle(acc, board, color, castling, _king_sq, side, dest, pass_through) do
    rights_key = {color, side}

    if Map.get(castling, rights_key, false) and
         not in_check?(board, color) and
         Enum.all?(pass_through, &is_nil(Board.get(board, &1))) and
         not Enum.any?(pass_through, fn sq -> attacked_by_any?(board, sq, Piece.opponent(color)) end) do
      [dest | acc]
    else
      acc
    end
  end

  defp find_king(board, color) do
    {sq, _} =
      Enum.find(board, fn {_sq, piece} ->
        piece.color == color and piece.kind == :king
      end)

    sq
  end

  defp attacked_by_any?(board, square, by_color) do
    board
    |> Board.squares_with(by_color)
    |> Enum.any?(fn {from, _piece} ->
      square in pseudo_legal_moves(board, from)
    end)
  end

  defp no_legal_moves?(board, color, opts) do
    board
    |> Board.squares_with(color)
    |> Enum.all?(fn {from, _piece} -> legal_moves(board, from, opts) == [] end)
  end

  defp friendly?(board, sq, color) do
    case Board.get(board, sq) do
      %Piece{color: ^color} -> true
      _ -> false
    end
  end

  defp enemy?(board, sq, color) do
    case Board.get(board, sq) do
      %Piece{color: c} when c != color -> true
      _ -> false
    end
  end
end
