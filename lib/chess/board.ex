defmodule Chess.Board do
  @moduledoc false

  alias Chess.Piece

  # Squares are {col, row} where col is 0..7 (a..h) and row is 0..7 (1..8).
  # White starts on rows 0-1, black on rows 6-7.

  @type square :: {0..7, 0..7}
  @type t :: %{square() => Piece.t()}

  @spec new() :: t()
  def new do
    white_back = back_rank(:white, 0)
    black_back = back_rank(:black, 7)
    white_pawns = for col <- 0..7, into: %{}, do: {{col, 1}, Piece.new(:white, :pawn)}
    black_pawns = for col <- 0..7, into: %{}, do: {{col, 6}, Piece.new(:black, :pawn)}

    Map.merge(white_back, white_pawns)
    |> Map.merge(black_pawns)
    |> Map.merge(black_back)
  end

  @spec get(t(), square()) :: Piece.t() | nil
  def get(board, square), do: Map.get(board, square)

  @spec put(t(), square(), Piece.t()) :: t()
  def put(board, square, piece), do: Map.put(board, square, piece)

  @spec delete(t(), square()) :: t()
  def delete(board, square), do: Map.delete(board, square)

  @spec move(t(), square(), square()) :: t()
  def move(board, from, to) do
    piece = Map.fetch!(board, from)
    board |> Map.delete(from) |> Map.put(to, piece)
  end

  @spec in_bounds?(square()) :: boolean()
  def in_bounds?({col, row}), do: col in 0..7 and row in 0..7

  @spec squares_with(t(), Piece.color()) :: [{square(), Piece.t()}]
  def squares_with(board, color) do
    Enum.filter(board, fn {_sq, piece} -> piece.color == color end)
  end

  @spec to_string(t()) :: String.t()
  def to_string(board) do
    col_labels = "  a b c d e f g h\n"

    rows =
      7..0//-1
      |> Enum.map(fn row ->
        rank = Integer.to_string(row + 1)
        squares = Enum.map(0..7, fn col -> square_glyph(board, {col, row}) end)
        rank <> " " <> Enum.join(squares, " ") <> " " <> rank
      end)

    col_labels <> Enum.join(rows, "\n") <> "\n" <> col_labels
  end

  defp square_glyph(board, square) do
    case Map.get(board, square) do
      nil -> "."
      %Piece{color: :white, kind: kind} -> piece_letter(kind) |> String.upcase()
      %Piece{color: :black, kind: kind} -> piece_letter(kind)
    end
  end

  defp piece_letter(:pawn), do: "p"
  defp piece_letter(:rook), do: "r"
  defp piece_letter(:knight), do: "n"
  defp piece_letter(:bishop), do: "b"
  defp piece_letter(:queen), do: "q"
  defp piece_letter(:king), do: "k"

  defp back_rank(color, row) do
    kinds = [:rook, :knight, :bishop, :queen, :king, :bishop, :knight, :rook]

    kinds
    |> Enum.with_index()
    |> Enum.into(%{}, fn {kind, col} -> {{col, row}, Piece.new(color, kind)} end)
  end
end
