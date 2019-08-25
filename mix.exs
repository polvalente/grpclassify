defmodule GRPClassify.MixProject do
  use Mix.Project

  def project do
    [
      app: :grpclassify,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
    [{:protobuf, "~> 0.6.1"}, {:grpc, github: "elixir-grpc/grpc"}]
  end
end