defmodule SlPortfolioWeb.MusicLive.Index do
  use SlPortfolioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    all_years = SlPortfolio.Music.list_all_years()
    categories = SlPortfolio.Music.list_categories()
    selected_category = :music
    current_year = Date.utc_today().year
    selected_year = current_year - 1

    # Load items for selected category and year
    items = load_items(selected_category, selected_year)

    {:ok,
     socket
     |> assign(:all_years, all_years)
     |> assign(:categories, categories)
     |> assign(:selected_category, selected_category)
     |> assign(:selected_year, selected_year)
     |> assign(:items, items)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_year", %{"year" => year_str}, socket) do
    year = String.to_integer(year_str)
    category = socket.assigns.selected_category
    items = load_items(category, year)

    {:noreply,
     socket
     |> assign(:selected_year, year)
     |> assign(:items, items)}
  end

  @impl true
  def handle_event("select_category", %{"category" => category_str}, socket) do
    category = String.to_existing_atom(category_str)
    year = socket.assigns.selected_year
    items = load_items(category, year)

    {:noreply,
     socket
     |> assign(:selected_category, category)
     |> assign(:items, items)}
  end

  defp load_items(category, year) do
    # Check if external first
    if SlPortfolio.Music.is_external?(category, year) do
      :external
    else
      SlPortfolio.Music.get_items_by_category_and_year(category, year)
    end
  end
end
