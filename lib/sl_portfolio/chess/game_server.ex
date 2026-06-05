defmodule SlPortfolio.Chess.GameServer do
  use GenServer

  alias Chess.Game
  alias SlPortfolio.PubSub
  alias SlPortfolio.Repo
  alias SlPortfolio.Chess.GameState

  @topic "chess:game"

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  def move(from, to, location \\ "Unknown"),
    do: GenServer.call(__MODULE__, {:move, from, to, location})

  def reset, do: GenServer.call(__MODULE__, :reset)

  def topic, do: @topic

  @impl true
  def init(_) do
    state =
      case Repo.one(GameState) do
        nil -> %{game: Game.new(), log: []}
        record -> :erlang.binary_to_term(record.state)
      end

    {:ok, state}
  end

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
        persist(new_state)
        Phoenix.PubSub.broadcast(PubSub, @topic, {:game_updated, new_state})
        {:reply, {:ok, new_state}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    new_state = %{game: Game.new(), log: []}
    persist(new_state)
    Phoenix.PubSub.broadcast(PubSub, @topic, {:game_updated, new_state})
    {:reply, :ok, new_state}
  end

  defp persist(state) do
    binary = :erlang.term_to_binary(state)

    case Repo.one(GameState) do
      nil ->
        Repo.insert!(%GameState{state: binary})

      record ->
        record
        |> Ecto.Changeset.change(state: binary)
        |> Repo.update!()
    end
  end
end
