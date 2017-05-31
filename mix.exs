defmodule BrandoPortfolio.Mixfile do
  use Mix.Project

  @version "0.1.0-dev"

  def project do
    [app: :brando_portfolio,
     version: @version,
     compilers: [:gettext, :phoenix] ++ Mix.compilers,
     elixirc_paths: elixirc_paths(Mix.env),
     test_coverage: [tool: ExCoveralls],
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: applications(:all) ++ [:ecto, :phoenix]
  defp applications(_all) do
    [:gettext, :logger]
  end

  defp deps do
    [{:phoenix, "~> 1.3.0-rc", override: true, optional: true},
     {:phoenix_ecto, "~> 3.2"},
     {:gettext, "~> 0.11"},
     {:mix_test_watch, "~> 0.2", only: :dev},

     # Test dependencies
     {:ex_machina, "~> 2.0", only: :test},
     {:excoveralls, "~> 0.5", only: :test},

     #{:brando, github: "twined/brando", branch: "develop", optional: true},
     {:brando, path: "../brando", override: true},

     # Documentation dependencies
     {:ex_doc, "~> 0.12", only: :docs},
     {:inch_ex, "~> 0.5", only: :docs}
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]
end
