defmodule Nerves.NTP.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_ntp,
      version: "0.3.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_clean: ["clean"],
      deps: deps(),
      docs: [extras: ["README.md"]],
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
      files: ["lib", "src/*.[ch]", "test", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md", "Makefile"],
      maintainers: ["Marcin Operacz", "Wojciech Mandrysz"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/evokly/nerves_ntp"}
    ]
  end

  defp deps do
    [
      {:muontrap, "~> 0.4"},
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.18.0", only: :dev}
    ]
  end
end
