defmodule Chess.Piece do
  @moduledoc false

  @type color :: :white | :black
  @type kind :: :pawn | :knight | :bishop | :rook | :queen | :king
  @type t :: %__MODULE__{color: color(), kind: kind()}

  defstruct [:color, :kind]

  def new(color, kind), do: %__MODULE__{color: color, kind: kind}

  def opponent(:white), do: :black
  def opponent(:black), do: :white
end
