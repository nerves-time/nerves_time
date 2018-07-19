defmodule Nerves.NTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_ntp,
      version: "0.2.0",
      elixir: "~> 1.6",
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
      mod: {Nerves.NTP, []}
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

  defp deps do
    [
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
