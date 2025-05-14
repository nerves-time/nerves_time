# SPDX-FileCopyrightText: 2025 Peter Ullrich
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesTime.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs NervesTime in your project using Igniter."
  end

  def example do
    "mix igniter.install nerves_time"
  end

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--file` or `-f` - Optional path to your `vm.args` file. Defaults to: `rel/vm.args.eex`
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NervesTime.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :nerves_time,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [
          file: :string
        ],
        # Default values for the options in the `schema`
        defaults: [
          file: "rel/vm.args.eex"
        ],
        # CLI aliases
        aliases: [
          f: :file
        ],
        # A list of options in the schema that are required
        required: []
      }
    end

    @multi_time_warp_flag """

    # Allow time warps so that the Erlang system time can more closely match the
    # OS system time.
    +C multi_time_warp
    """

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      args_path = igniter.args.options[:file]

      igniter
      |> Igniter.update_file(
        args_path,
        fn updater ->
          Rewrite.Source.update(updater, :content, fn content ->
            if content =~ "+C multi_time_warp" do
              content
            else
              [header | rest] = String.split(content, "\n")
              content = [header, @multi_time_warp_flag] ++ rest
              Enum.join(content, "\n")
            end
          end)
        end
      )
    end
  end
else
  defmodule Mix.Tasks.NervesTime.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'nerves_time.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
