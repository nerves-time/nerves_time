defmodule Nerves.NTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_ntp,
      version: "0.3.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nerves.NTP.Application, []}
    ]
  end

  defp description do
    """
    Synchronize system time using Busybox `ntpd`.
    """
  end

  defp package do
    [
      maintainers: ["Marcin Operacz", "Wojciech Mandrysz"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/evokly/nerves_ntp"}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
