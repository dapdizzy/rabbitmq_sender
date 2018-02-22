defmodule RabbitMQSender.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rabbitmq_sender,
      version: "0.1.8",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "RabbitMQSender"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 0.2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description do
    "This is a GenServer-ish implementation RabbitMQ Sender."
  end

  defp package do
    [
      name: "rabbitmq_sender",
      maintainers: ["Dmitry A. Pyatkov"],
      licenses: ["Apache 2.0"],
      files: ["lib", "mix.exs"],
      links: %{"No Link" => "http://localhost"}
    ]
  end
end
