defmodule SlPortfolio.Music do
  @moduledoc """
  Context module for managing lists data (Music, Shows, Books, Games) by year.
  """

  @start_year 2019
  @categories [:music, :shows, :books, :games]

  @data_by_year %{
    2019 => %{
      music: %{external_url: "https://medium.com/@slando"},
      shows: %{},
      books: %{},
      games: %{}
    },
    2020 => %{
      music: %{external_url: "https://medium.com/@slando"},
      shows: %{},
      books: %{},
      games: %{}
    },
    2021 => %{
      music: [
        %{
          title: "Example Album 1",
          rank: 1,
          fav_songs: ["Song A", "Song B", "Song C"],
          image_src: "/images/albums/2021/album1.jpg"
        },
        %{
          title: "Example Album 2",
          rank: 2,
          fav_songs: ["Song D", "Song E"],
          image_src: "/images/albums/2021/album2.jpg"
        }
      ],
      shows: %{},
      books: %{},
      games: %{}
    },
    2025 => %{
      music: [
        %{
          title: "I Love My Computer",
          artist: "Ninajirachi",
          rank: 1,
          fav_songs: ["iPod Touch", "London Song"],
          image_src: "/images/albums/love_my_computer_2.png"
        },
        %{
          title: "viagr aboys",
          artist: "Viagra Boys",
          rank: 2,
          fav_songs: ["Man Made of Meat", "Dirty Boyz"],
          image_src: "/images/albums/viagra_boys.png"
        },
        %{
          title: "Don't Tap The Glass",
          artist: "Tyler, The Creator",
          rank: 3,
          fav_songs: ["Big Poe", "Sugar On My Tongue"],
          image_src: "/images/albums/don't_tap_the_glass.png"
        },
        %{
          title: "They Left Me With The Sword/Gun (Double EP)",
          artist: "Paris Texas",
          rank: 4,
          fav_songs: ["infinyte", "Stripper Song"],
          image_src: "/images/albums/paris_texas.png"
        },
        %{
          title: "Getting Killed",
          artist: "Geese",
          rank: 5,
          fav_songs: ["Husbands", "Cobra"],
          image_src: "/images/albums/getting_killed.png"
        },
        %{
          title: "Let God Sort Em Out",
          artist: "Clipse",
          rank: 6,
          fav_songs: ["Chains & Whips", "MTBTTF"],
          image_src: "/images/albums/clipse.png"
        }
      ],
      shows: [
        %{
          title: "The Rehearsal",
          artist: "Season 2",
          rank: 1,
          image_src: "/images/shows/rehearsal.jpg"
        },
        %{
          title: "Severance",
          artist: "Season 2",
          rank: 2,
          image_src: "/images/shows/severance.webp"
        },
        %{
          title: "Long Story Short",
          rank: 5,
          image_src: "/images/shows/long_story_short.jpg"
        },
        %{
          title: "Pluribus",
          rank: 3,
          image_src: "/images/shows/pluribus.webp"
        }
      ],
      books: [
        %{
          description:
            "Embarrassingly, I only read two books this year: The Inner Game of Tennis by Timothy Gallwey and Value(s) by Mark Carney. And I wouldn't say I would recommend Value(s) either. But I'm determined to read more in 2026 and am putting this here to motivate myself."
        }
      ],
      games: [
        %{
          title: "Hollow Knight: Silksong",
          rank: 1,
          image_src: "/images/games/silksong.jpeg"
        },
        %{
          title: "Hades II",
          rank: 2,
          image_src: "/images/games/hades_2.jpg"
        }
      ]
    }
  }

  @spec list_categories() :: [:books | :games | :music | :shows, ...]
  @doc """
  Returns a list of all available categories.
  """
  def list_categories do
    @categories
  end

  @doc """
  Returns a list of all years from 2019 to the current year, sorted in ascending order.
  """
  def list_all_years do
    current_year = Date.utc_today().year

    @start_year..current_year
    |> Enum.to_list()
    |> Enum.sort(:asc)
  end

  @doc """
  Returns a list of years that have data for a given category.
  """
  def list_years_with_data(category) when category in @categories do
    @data_by_year
    |> Enum.filter(fn {_year, categories} ->
      Map.has_key?(categories, category)
    end)
    |> Enum.map(fn {year, _categories} -> year end)
    |> Enum.sort(:desc)
  end

  def list_years_with_data(_), do: []

  @doc """
  Checks if a year exists in the data for a given category.
  """
  def has_year?(category, year) when category in @categories and is_integer(year) do
    case Map.get(@data_by_year, year) do
      nil -> false
      categories -> Map.has_key?(categories, category)
    end
  end

  def has_year?(_category, _year), do: false

  @doc """
  Checks if a year has an external URL for a given category (not local data).
  """
  def is_external?(category, year) when category in @categories and is_integer(year) do
    case get_category_data(category, year) do
      %{external_url: _url} -> true
      _ -> false
    end
  end

  def is_external?(_category, _year), do: false

  @doc """
  Returns the external URL for a given category and year, or nil if not external.
  """
  def get_external_url(category, year) when category in @categories and is_integer(year) do
    case get_category_data(category, year) do
      %{external_url: url} -> url
      _ -> nil
    end
  end

  def get_external_url(_category, _year), do: nil

  @doc """
  Returns the list of items for a given category and year.
  Returns an empty list if the year doesn't exist or is external.
  """

  def get_items_by_category_and_year(category, year)
      when category in @categories and is_integer(year) do
    case get_category_data(category, year) do
      items when is_list(items) -> items
      _ -> []
    end
  end

  def get_items_by_category_and_year(_category, _year), do: []

  # Helper function to get category data for a year
  defp get_category_data(category, year) do
    @data_by_year
    |> Map.get(year, %{})
    |> Map.get(category)
  end
end
