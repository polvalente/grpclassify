defmodule GRPClassify.MixProject do
  use Mix.Project

  def project do
    [
      app: :grpclassify,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GRPClassify.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:protobuf, "~> 0.6.1"},
      {:grpc, github: "elixir-grpc/grpc"},
      {:cowboy,
       [
         env: :prod,
         git: "https://github.com/elixir-grpc/cowboy.git",
         tag: "grpc-2.6.3",
         override: true
       ]},
      {:phoenix, "~> 1.4.9"},
      {:poison, "~> 4.0.1"}
    ]
  end
end
