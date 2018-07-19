defmodule Nerves.Ntp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nerves_ntp,
      version: "0.1.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger],
      mod: {Nerves.Ntp, []}
    ]
  end

  defp description do
    """
    OTP application to sync time using busybox `ntpd` command.
    """
  end

  defp package do
    [
      # These are the default files included in the package
      name: :nerves_ntp,
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Marcin Operacz", "Wojciech Mandrysz"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/evokly/nerves_ntp"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    []
  end
end
