defmodule Chess.Move do
  @moduledoc false

  alias Chess.{Board, Piece}

  @type t :: %__MODULE__{
          from: Board.square(),
          to: Board.square(),
          piece: Piece.t(),
          captured: Piece.t() | nil,
          castle: :kingside | :queenside | nil,
          promotion: Piece.kind() | nil
        }

  defstruct [:from, :to, :piece, :captured, :castle, :promotion]
end
