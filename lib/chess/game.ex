defmodule Chess.Game do
  @moduledoc false

  alias Chess.{Board, Move, Piece, Rules}

  @type status :: :playing | :checkmate | :stalemate
  @type side :: :kingside | :queenside

  @type t :: %__MODULE__{
          board: Board.t(),
          turn: Piece.color(),
          castling: %{{Piece.color(), side()} => boolean()},
          en_passant: Board.square() | nil,
          halfmove_clock: non_neg_integer(),
          fullmove_number: pos_integer(),
          status: status(),
          history: [Move.t()]
        }

  defstruct board: nil,
            turn: :white,
            castling: %{
              {:white, :kingside} => true,
              {:white, :queenside} => true,
              {:black, :kingside} => true,
              {:black, :queenside} => true
            },
            en_passant: nil,
            halfmove_clock: 0,
            fullmove_number: 1,
            status: :playing,
            history: []

  @spec new() :: t()
  def new, do: %__MODULE__{board: Board.new()}

  @spec legal_moves(t(), Board.square()) :: [Board.square()]
  def legal_moves(%__MODULE__{status: s}, _from) when s != :playing, do: []

  def legal_moves(game, from) do
    case Board.get(game.board, from) do
      %Piece{color: color} when color == game.turn ->
        Rules.legal_moves(game.board, from, castling: game.castling, en_passant: game.en_passant)

      _ ->
        []
    end
  end

  @spec move(t(), Board.square(), Board.square()) :: {:ok, t()} | {:error, atom()}
  def move(%__MODULE__{status: s}, _from, _to) when s != :playing, do: {:error, :game_over}

  def move(game, from, to) do
    if to in legal_moves(game, from) do
      {:ok, apply_move(game, from, to)}
    else
      {:error, :illegal_move}
    end
  end

  # --- private ---

  defp apply_move(%__MODULE__{} = game, from, to) do
    piece = Board.get(game.board, from)
    captured = captured_piece(game.board, piece, to, game.en_passant)

    board = Rules.apply_move(game.board, from, to, game.en_passant)
    promotion = promotion_kind(board, to, piece)
    board = maybe_promote(board, to, piece)
    board = maybe_apply_castle(board, piece, from, to)

    opponent = Piece.opponent(game.turn)
    new_castling = update_castling(game.castling, piece, from)
    new_ep = new_en_passant(piece, from, to)
    new_half = if capture_or_pawn?(game.board, piece, to), do: 0, else: game.halfmove_clock + 1
    new_full = if game.turn == :black, do: game.fullmove_number + 1, else: game.fullmove_number

    opts = [castling: new_castling, en_passant: new_ep]

    new_status =
      cond do
        Rules.checkmate?(board, opponent, opts) -> :checkmate
        Rules.stalemate?(board, opponent, opts) -> :stalemate
        true -> :playing
      end

    move_record = %Move{
      from: from,
      to: to,
      piece: piece,
      captured: captured,
      castle: castle_side(piece, from, to),
      promotion: promotion
    }

    %__MODULE__{
      game
      | board: board,
        turn: opponent,
        castling: new_castling,
        en_passant: new_ep,
        halfmove_clock: new_half,
        fullmove_number: new_full,
        status: new_status,
        history: [move_record | game.history]
    }
  end

  defp captured_piece(board, %Piece{kind: :pawn, color: color}, to, en_passant) when to == en_passant do
    capture_row = if color == :white, do: elem(to, 1) - 1, else: elem(to, 1) + 1
    Board.get(board, {elem(to, 0), capture_row})
  end

  defp captured_piece(board, _piece, to, _en_passant) do
    Board.get(board, to)
  end

  defp promotion_kind(_board, {_col, row}, %Piece{kind: :pawn, color: color}) do
    back_rank = if color == :white, do: 7, else: 0
    if row == back_rank, do: :queen, else: nil
  end

  defp promotion_kind(_board, _to, _piece), do: nil

  # Promote pawns that reach the back rank (always to queen for now).
  defp maybe_promote(board, {_col, row} = to, %Piece{kind: :pawn, color: color}) do
    back_rank = if color == :white, do: 7, else: 0

    if row == back_rank do
      Board.put(board, to, Piece.new(color, :queen))
    else
      board
    end
  end

  defp maybe_promote(board, _to, _piece), do: board

  defp maybe_apply_castle(board, %Piece{kind: :king}, {4, row}, {6, row}) do
    Board.move(board, {7, row}, {5, row})
  end

  defp maybe_apply_castle(board, %Piece{kind: :king}, {4, row}, {2, row}) do
    Board.move(board, {0, row}, {3, row})
  end

  defp maybe_apply_castle(board, _piece, _from, _to), do: board

  defp castle_side(%Piece{kind: :king}, {4, row}, {6, row}), do: :kingside
  defp castle_side(%Piece{kind: :king}, {4, row}, {2, row}), do: :queenside
  defp castle_side(_piece, _from, _to), do: nil

  defp update_castling(castling, %Piece{kind: :king, color: color}, _from) do
    castling
    |> Map.put({color, :kingside}, false)
    |> Map.put({color, :queenside}, false)
  end

  defp update_castling(castling, %Piece{kind: :rook, color: color}, {0, _}) do
    Map.put(castling, {color, :queenside}, false)
  end

  defp update_castling(castling, %Piece{kind: :rook, color: color}, {7, _}) do
    Map.put(castling, {color, :kingside}, false)
  end

  defp update_castling(castling, _piece, _from), do: castling

  defp new_en_passant(%Piece{kind: :pawn, color: :white}, {col, 1}, {col2, 3}) when col == col2,
    do: {col, 2}

  defp new_en_passant(%Piece{kind: :pawn, color: :black}, {col, 6}, {col2, 4}) when col == col2,
    do: {col, 5}

  defp new_en_passant(_piece, _from, _to), do: nil

  defp capture_or_pawn?(board, piece, to) do
    piece.kind == :pawn or not is_nil(Board.get(board, to))
  end
end
