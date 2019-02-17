defmodule Firebirdex.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project() do
    [
      app: :firebirdex,
      version: @version,
      elixir: "~> 1.4",
      name: "Firebirdex",
      description: "Firebird driver for Elixir",
      source_url: "https://github.com/nakagami/firebirdex",
      package: package(),
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger],
    ]
  end

  defp package do
    [
      maintainers: ["Hajime Nakagami"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/nakagami/firebirdex"}
    ]
  end

  defp deps() do
    [
      {:db_connection, "~> 2.0"},
      {:decimal, "~> 1.6"},
      {:efirebirdsql, "~> 0.5.5"},
    ]
  end

end

