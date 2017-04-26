defmodule Remodel.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [
      app: :remodel,
      version: @version,
      elixir: "~> 1.0",
      deps: deps(),

      # Hex
      description: description(),
      package: package()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp description do
    """
Remodel is an Elixir presenter package used to transform data structures.

This is especially useful when a desired representation doesn't match the schema defined within the database.
"""
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [
     licenses: ["Apache 2.0"],
     links: %{"GitHub": "https://github.com/stavro/remodel"},
     contributors: ["Sean Stavropoulos"]
     ]
  end
end
