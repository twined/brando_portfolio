use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :brando_portfolio, BrandoPortfolio.Integration.Endpoint,
  http: [port: 4001],
  server: false,
  secret_key_base: "verysecret"

config :logger, level: :warn

config :brando_portfolio, BrandoPortfolio.Integration.TestRepo,
  url: "ecto://postgres:postgres@localhost/brando_portfolio_test",
  adapter: Ecto.Adapters.Postgres,
  extensions: [{Postgrex.Extensions.JSON, library: Poison}],
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1,
  max_overflow: 0


config :brando, :router, BrandoPortfolio.Router
config :brando, :endpoint, BrandoPortfolio.Integration.Endpoint
config :brando, :repo, BrandoPortfolio.Integration.TestRepo
config :brando, :helpers, BrandoPortfolio.Router.Helpers

config :brando, :media_url, "/media"
config :brando, :media_path, Path.join([Mix.Project.app_path, "tmp", "media"])

config :brando, Brando.Menu, [
  modules: [Brando.Portfolio.Menu],
  colors: ["#FBA026;", "#F87117;", "#CF3510;", "#890606;", "#FF1B79;",
           "#520E24;", "#8F2041;", "#DC554F;", "#FF905E;", "#FAC51C;",
           "#D6145F;", "#AA0D43;", "#7A0623;", "#430202;", "#500422;",
           "#870B46;", "#D0201A;", "#FF641A;"]]

config :brando, Brando.Villain, parser: Brando.Villain.Parser.Default
config :brando, Brando.Villain, extra_blocks: []

config :brando, :default_language, "nb"
config :brando, :admin_default_language, "nb"
config :brando, :languages, [
  [value: "nb", text: "Norsk"],
  [value: "en", text: "English"]
]
config :brando, :admin_languages, [
  [value: "nb", text: "Norsk"],
  [value: "en", text: "English"]
]

config :brando, Brando.Images, [
  default_config: %{
    allowed_mimetypes: ["image/jpeg", "image/png"],
    default_size: :medium, size_limit: 10240000,
    upload_path: Path.join("images", "default"),
    sizes: %{
      "small" =>  %{"size" => "300", "quality" => 100},
      "medium" => %{"size" => "500", "quality" => 100},
      "large" =>  %{"size" => "700", "quality" => 100},
      "xlarge" => %{"size" => "900", "quality" => 100},
      "thumb" =>  %{"size" => "150x150", "quality" => 100, "crop" => true},
      "micro" =>  %{"size" => "25x25", "quality" => 100, "crop" => true}
    }
  },
  optimize: [
    png: [
      bin: "cp",
      args: "%{filename} %{new_filename}"
    ]
  ]
]