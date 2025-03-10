# SPDX-FileCopyrightText: 2016 Marcin Operacz
# SPDX-FileCopyrightText: 2019 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
# Clean up the temporary socket file
socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")
File.rm(socket_path)

# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

ExUnit.start()
