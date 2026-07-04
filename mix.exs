defmodule Firebirdex.Mixfile do
  use Mix.Project

  @version "0.3.13"

  def project() do
    [
      app: :firebirdex,
      version: @version,
      elixir: "~> 1.18",
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
      mod: {Firebirdex.Application, []}
    ]
  end

  defp package do
    [
      maintainers: ["Hajime Nakagami"],
      licenses: ["MIT"],
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
      {:db_connection, "~> 2.10"},
      {:decimal, "~> 3.1"},
      {:efirebirdsql, "~> 0.9"},
      {:codepagex, "~> 0.1"},
      {:tz, "~> 0.28"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

end
