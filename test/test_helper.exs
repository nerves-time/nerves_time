# Clean up the temporary socket file
socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")
File.rm(socket_path)

ExUnit.start()
