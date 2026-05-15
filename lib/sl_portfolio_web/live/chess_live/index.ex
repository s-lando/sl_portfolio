defmodule SlPortfolioWeb.ChessLive.Index do
  use SlPortfolioWeb, :live_view

  alias SlPortfolio.Chess.{GameServer, Geolocation}

  @impl true
  def mount(_params, _session, socket) do
    ip = extract_ip(socket)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SlPortfolio.PubSub, GameServer.topic())
    end

    %{game: game, log: log} = GameServer.get_state()

    {:ok,
     socket
     |> assign(game_assigns(game))
     |> assign(:log, log)
     |> assign(:ip, ip)
     |> assign(:selected, nil)
     |> assign(:legal_moves, [])}
  end

  @impl true
  def handle_event("select_square", %{"col" => col, "row" => row}, socket) do
    square = {String.to_integer(col), String.to_integer(row)}
    game = socket.assigns.game
    selected = socket.assigns.selected

    cond do
      selected != nil and square in socket.assigns.legal_moves ->
        location = Geolocation.lookup(socket.assigns.ip)

        case GameServer.move(selected, square, location) do
          {:ok, %{game: new_game, log: log}} ->
            {:noreply,
             socket
             |> assign(game_assigns(new_game))
             |> assign(:log, log)
             |> assign(:selected, nil)
             |> assign(:legal_moves, [])}

          {:error, _} ->
            {:noreply, socket |> assign(:selected, nil) |> assign(:legal_moves, [])}
        end

      has_current_piece?(game, square) ->
        {:noreply,
         socket
         |> assign(:selected, square)
         |> assign(:legal_moves, Chess.legal_moves(game, square))}

      true ->
        {:noreply, socket |> assign(:selected, nil) |> assign(:legal_moves, [])}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    GameServer.reset()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_updated, %{game: game, log: log}}, socket) do
    {:noreply,
     socket
     |> assign(game_assigns(game))
     |> assign(:log, log)
     |> assign(:selected, nil)
     |> assign(:legal_moves, [])}
  end

  defp extract_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: addr} -> addr |> :inet.ntoa() |> to_string()
      _ -> "127.0.0.1"
    end
  end

  defp game_assigns(game) do
    last_move_squares =
      case game.history do
        [] -> MapSet.new()
        [%Chess.Move{from: from, to: to} | _] -> MapSet.new([from, to])
      end

    check_square =
      if game.status == :playing and Chess.Rules.in_check?(game.board, game.turn) do
        Chess.Board.squares_with(game.board, game.turn)
        |> Enum.find_value(fn {sq, piece} -> if piece.kind == :king, do: sq end)
      end

    %{game: game, last_move_squares: last_move_squares, check_square: check_square}
  end

  defp has_current_piece?(game, square) do
    case Chess.Board.get(game.board, square) do
      %Chess.Piece{color: color} -> color == game.turn
      nil -> false
    end
  end

  # Template helpers

  def square_classes(dark, selected, last_move, legal, in_check) do
    ["square"]
    |> add_class(dark, "dark", "light")
    |> add_class(selected, "selected")
    |> add_class(last_move and not selected, "last-move")
    |> add_class(legal, "legal")
    |> add_class(in_check, "in-check")
    |> Enum.join(" ")
  end

  defp add_class(classes, true, name), do: [name | classes]
  defp add_class(classes, false, _name), do: classes
  defp add_class(classes, true, name, _alt), do: [name | classes]
  defp add_class(classes, false, _name, alt), do: [alt | classes]

  def piece_glyph(%Chess.Piece{color: color, kind: kind}) do
    glyphs = %{
      white: %{king: "♔", queen: "♕", rook: "♖", bishop: "♗", knight: "♘", pawn: "♙"},
      black: %{king: "♚", queen: "♛", rook: "♜", bishop: "♝", knight: "♞", pawn: "♟"}
    }

    glyphs[color][kind]
  end

  def status_message(:checkmate), do: "Checkmate!"
  def status_message(:stalemate), do: "Stalemate — it's a draw."

  def move_label(%Chess.Move{piece: piece, from: from, to: to, castle: castle}) do
    cond do
      castle == :kingside -> "O-O"
      castle == :queenside -> "O-O-O"
      true -> "#{piece_glyph(piece)} #{square_name(from)}→#{square_name(to)}"
    end
  end

  def format_timestamp(%DateTime{} = dt) do
    "#{dt.year}-#{pad(dt.month)}-#{pad(dt.day)} #{pad(dt.hour)}:#{pad(dt.minute)} UTC"
  end

  defp pad(n), do: String.pad_leading(Integer.to_string(n), 2, "0")
  defp square_name({col, row}), do: <<?a + col>> <> Integer.to_string(row + 1)
end
