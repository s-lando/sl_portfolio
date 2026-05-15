defmodule SlPortfolio.Chess.GameServer do
  use GenServer

  alias Chess.Game
  alias SlPortfolio.PubSub

  @topic "chess:game"

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  def move(from, to, location \\ "Unknown"),
    do: GenServer.call(__MODULE__, {:move, from, to, location})

  def reset, do: GenServer.call(__MODULE__, :reset)

  def topic, do: @topic

  @impl true
  def init(_), do: {:ok, %{game: Game.new(), log: []}}

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:move, from, to, location}, _from, %{game: game, log: log} = state) do
    case Chess.move(game, from, to) do
      {:ok, new_game} ->
        entry = %{
          move: hd(new_game.history),
          location: location,
          at: DateTime.utc_now()
        }

        new_state = %{game: new_game, log: [entry | log]}
        Phoenix.PubSub.broadcast(PubSub, @topic, {:game_updated, new_state})
        {:reply, {:ok, new_state}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    new_state = %{game: Game.new(), log: []}
    Phoenix.PubSub.broadcast(PubSub, @topic, {:game_updated, new_state})
    {:reply, :ok, new_state}
  end
end
