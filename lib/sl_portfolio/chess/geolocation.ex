defmodule SlPortfolio.Chess.Geolocation do
  @moduledoc false

  @local_ips ["127.0.0.1", "::1"]

  @spec lookup(String.t()) :: String.t()
  def lookup(ip) when ip in @local_ips, do: "Local"

  def lookup(ip) do
    url = ~c"http://ip-api.com/json/#{ip}?fields=city,regionName,country,status"

    case :httpc.request(:get, {url, []}, [{:timeout, 3000}], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        body
        |> to_string()
        |> Jason.decode!()
        |> format_location()

      _ ->
        "Unknown"
    end
  end

  defp format_location(%{"status" => "success", "city" => city, "country" => country})
       when city != "" and country != "" do
    "#{city}, #{country}"
  end

  defp format_location(%{"status" => "success", "country" => country})
       when country != "" do
    country
  end

  defp format_location(_), do: "Unknown"
end
