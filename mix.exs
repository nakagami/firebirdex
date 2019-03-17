defmodule Firebirdex.Mixfile do
  use Mix.Project

  @version "0.0.5"

  def project() do
    [
      app: :firebirdex,
      version: @version,
      elixir: "~> 1.4",
      name: "Firebirdex",
      description: "Firebird driver for Elixir",
      source_url: "https://github.com/nakagami/firebirdex",
      package: package(),
      docs: docs(),
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

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps() do
    [
      {:db_connection, "~> 2.0"},
      {:decimal, "~> 1.6"},
      {:efirebirdsql, "~> 0.5.8"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

end

