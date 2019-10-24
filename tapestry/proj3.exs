

try do
  # Check if we have correct arguments

	if length(System.argv) != 2 do
		raise ArgumentError
	end
	# Pick up the arguments
	[num_nodes, num_requests] = System.argv
  num_nodes = elem(Integer.parse(num_nodes), 0)
  num_requests = elem(Integer.parse(num_requests), 0)

  # Call to helper function to add the given number of workers to the Supervisor
  id_to_pid = Tapestryclasses.Utils.add_children(Tapestryclasses.Node, num_requests, num_nodes, self())

  pid_to_id = Enum.reduce(id_to_pid, %{}, fn {k, vs}, acc ->
    Map.put(acc,vs,k)
  end)

  Tapestryclasses.Utils.set_id_pid_table(id_to_pid, pid_to_id)

  # List of all GUIDs
  pids = Map.keys(pid_to_id)
  # Initiate creation of routing tables
  # TODO: Now that we have to dynamically add nodes as well we'll maybe just create tables for 95% of the nodes and
  # AFTER that step is done then we add the remaining nodes and handle the update table case
  # Right now just adding all routing tables
  start_time = Time.utc_now()
  IO.puts("Triggering creation of routing tables")
  Enum.each(pids, fn x->
    Tapestryclasses.Node.update_state(x)
  end)

  receive do
    {:routing_tables_ready, _pid} -> IO.puts("Routing tables ready. Can send messages now")
  end
  end_time = Time.utc_now()
  time_diff = Time.diff(end_time, start_time, :millisecond)
  IO.puts("Creation of routing tables takes #{time_diff} milliseconds")
  # TODO: Logic for dynamically adding the rest of the routing tables goes here

  # The assumption here is that the routing tables are ready.
  # Maybe will have to give this some more thought

  # This is the code to send messages once the routing tables are ready
  message ="message"
  Enum.each(pids, fn x->
    x_guid = Map.get pid_to_id, x
    id_to_pid_temp = id_to_pid
    {_val, id_to_pid_temp} = Map.pop(id_to_pid_temp, x_guid)

    id_to_pid_temp = Map.keys(id_to_pid_temp)
    dest = Enum.take_random(id_to_pid_temp, num_requests)

    Enum.each(dest, fn y ->
      # IO.puts "Send message from #{x} to #{y}"
      Tapestryclasses.Node.send_first_message(x, y, message)
      # Send message to destination (y) from the source (x)
    end)
  end
  )

  receive do
    {:terminate_now, _pid} -> IO.puts("Terminating Supervisor")
  end
  Supervisor.stop(Tapestryclasses.Supervisor)
  final_time = Time.utc_now()
  time_diff = Time.diff(final_time, start_time, :millisecond)
  IO.puts("Total time taken #{time_diff} milliseconds")

rescue
	_e in ArgumentError ->  IO.puts("Script Failed!")
	System.stop(1)
end
