defmodule SlPortfolioWeb.PageController do
  use SlPortfolioWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end

  def portfolio(conn, _params) do
    render(conn, "portfolio.html")
  end

  def shadow(conn, _params) do
    render(conn, "shadow.html")
  end
end
