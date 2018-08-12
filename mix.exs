defmodule Nerves.Time.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_time,
      version: "0.2.0",
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
      mod: {Nerves.Time.Application, []}
    ]
  end

  defp description do
    "Keep time in sync on Nerves devices"
  end

  defp package do
    [
      files: [
        "lib",
        "src/*.[ch]",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "Makefile"
      ],
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/nerves_time"}
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
