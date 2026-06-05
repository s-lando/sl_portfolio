import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sl_portfolio, SlPortfolioWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "G4zC78G9JCRJoIVq9/8XCgS8j3aKvS0HtPlnfySTMI/CZloNImvtUFHkrrB2mc38",
  server: false

# In test we don't send emails.
config :sl_portfolio, SlPortfolio.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :sl_portfolio, SlPortfolio.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sl_portfolio_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
