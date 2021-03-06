defmodule Home.MixProject do
  use Mix.Project

  def project do
    [
      app: :home,
      version: "0.1.0",
      description: "My personal website",
      package: [
        licenses: ["MIT"],
        links: %{"home" => "https://myrrlyn.net/"}
      ],
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    base_apps = [:logger, :runtime_tools, :timex, :crypto]

    [
      mod: {Home.Application, []},
      extra_applications:
        if Mix.env() == :dev do
          [:os_mon | base_apps]
        else
          base_apps
        end
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:phoenix_etag, "~> 0.1"},
      {:phoenix_markdown, "~> 1.0"},
      {:phoenix_haml, "~> 0.2"},
      {:earmark, "~> 1.4"},
      {:earmark_parser, "~> 1.4"},
      {:timex, "~> 3.7"},
      {:yaml_elixir, "~> 2.6"},
      {:gravatar, "~> 0.1"},
      {:statistics, "~> 0.6"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      serve: ["cmd npm run deploy --prefix ./assets", "phx.digest", "phx.server"],
      test: ["test"]
    ]
  end
end
