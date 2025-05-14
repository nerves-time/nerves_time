# SPDX-FileCopyrightText: 2025 Peter Ullrich
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesTime.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "install" do
    test "returns an error if the vm.args.eex does not exist at the default filepath" do
      assert {:error, [warning]} =
               test_project()
               |> Igniter.compose_task("nerves_time.install", [])
               |> apply_igniter()

      assert warning =~ "Required rel/vm.args.eex but it did not exist"
    end

    test "adds the print statement to an existing iex.exs file" do
      vm_args = """
      ## Customize flags given to the VM: https://www.erlang.org/doc/apps/erts/erl_cmd.html

      ## Do not set -name or -sname here. Prefer configuring them at runtime
      ## Configure -setcookie in the mix.exs release section or at runtime
      """

      test_project(files: %{"rel/vm.args.eex" => vm_args})
      |> Igniter.compose_task("nerves_time.install", [])
      |> assert_has_patch("rel/vm.args.eex", """
        + |# Allow time warps so that the Erlang system time can more closely match the
        + |# OS system time.
        + |+C multi_time_warp
        + |
        + |
      """)
    end

    test "is noop if the erlang flag already exists in the vm.args.eex file" do
      vm_args = """
      ## Customize flags given to the VM: https://www.erlang.org/doc/apps/erts/erl_cmd.html

      ## Do not set -name or -sname here. Prefer configuring them at runtime
      ## Configure -setcookie in the mix.exs release section or at runtime

      # Allow time warps so that the Erlang system time can more closely match the
      # OS system time.
      +C multi_time_warp
      """

      test_project(files: %{"rel/vm.args.eex" => vm_args})
      |> Igniter.compose_task("nerves_time.install", [])
      |> assert_unchanged("rel/vm.args.eex")
    end

    test "adds the print statement to an vm.args.eex file at a provided filepath" do
      vm_args = """
      ## Customize flags given to the VM: https://www.erlang.org/doc/apps/erts/erl_cmd.html

      ## Do not set -name or -sname here. Prefer configuring them at runtime
      ## Configure -setcookie in the mix.exs release section or at runtime
      """

      test_project(files: %{"somewhere/vm.args.eex" => vm_args})
      |> Igniter.compose_task("nerves_time.install", ["--file", "somewhere/vm.args.eex"])
      |> assert_has_patch("somewhere/vm.args.eex", """
        + |# Allow time warps so that the Erlang system time can more closely match the
        + |# OS system time.
        + |+C multi_time_warp
        + |
        + |
      """)
    end
  end
end
