defmodule ExFuture.Mixfile do
  use Mix.Project

  def project do
    [ app: :exfuture,
      version: "0.0.1",
      elixir: ">= 1.0.0",
      deps: deps,
      test_coverage: [tool: ExCoveralls] ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:http_server] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  def deps do
    [
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.1"},
      {:httpotion, "~> 2.1.0"},
      {:excoveralls, "~> 0.3", only: [:dev, :test]},
      {:http_server, github: "parroty/http_server"},
    ]
  end
end
