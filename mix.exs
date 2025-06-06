defmodule NervesTime.MixProject do
  use Mix.Project

  @version "0.4.8"
  @description "Keep time in sync on Nerves devices"
  @source_url "https://github.com/nerves-time/nerves_time"

  def project do
    [
      app: :nerves_time,
      version: @version,
      elixir: "~> 1.13",
      description: @description,
      package: package(),
      source_url: @source_url,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      make_error_message: "",
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return, :underspecs]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      env: [await_initialization_timeout: 0],
      extra_applications: [:logger],
      mod: {NervesTime.Application, []}
    ]
  end

  def cli do
    [preferred_envs: %{docs: :docs, "hex.publish": :docs, "hex.build": :docs}]
  end

  defp package do
    %{
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES",
        "src/*.[ch]",
        "Makefile",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" => "https://api.reuse.software/info/github.com/nerves-time/nerves_time"
      }
    }
  end

  defp deps do
    [
      {:muontrap, "~> 1.0 or ~> 0.5"},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false},
      {:dialyxir, "~> 1.4.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
