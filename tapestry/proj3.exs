

try do
  # Check if we have correct arguments

	if length(System.argv) != 2 do
		raise ArgumentError
	end
	# Pick up the arguments
	[num_nodes, num_requests] = System.argv
  num_nodes = elem(Integer.parse(num_nodes), 0)
  num_requests = elem(Integer.parse(num_requests), 0)

  IO.puts("num nodes #{num_nodes}")
  IO.puts("num reqs #{num_requests}")
	# We first need to build the topology based on the given input and then
	# based on the given algo figure out which algo to trigger
	IO.puts("The number of children is #{inspect Supervisor.count_children(Tapestryclasses.Supervisor)}")

  # Call to helper function to add the given number of workers to the Supervisor
  id_to_pid = Tapestryclasses.Utils.add_children(Tapestryclasses.Node, num_requests, num_nodes, self())

  pid_to_id = Enum.reduce(id_to_pid, %{}, fn {k, vs}, acc ->
    Map.put(acc,vs,k)
  end)

  Tapestryclasses.Utils.set_id_pid_table(id_to_pid, pid_to_id)

  # List of all GUIDs
  guids = Map.keys(id_to_pid)
  # Initiate creation of routing tables
  receive do
    {:routing_tables_ready, _pid} -> IO.puts("Routing tables ready. Can send messages now")
  end
  # The assumption here is that the routing tables are ready.
  # Maybe will have to give this some more thought

  Enum.each(guids, fn x->

    id_to_pid_temp = id_to_pid
    {val, id_to_pid_temp} = Map.pop(id_to_pid_temp, x)
    id_to_pid_temp = Map.keys(id_to_pid_temp)
    dest = Enum.take_random(id_to_pid_temp, num_requests)

    Enum.each(dest, fn y ->
      # Send message to destination (y) from the source (x)
    end)
  end
  )

  receive do
    {:terminate_now, _pid} -> IO.puts("Terminating Supervisor")
  end
  Supervisor.stop(Tapestryclasses.Supervisor)
rescue
	e in ArgumentError ->  e
	System.stop(1)
end
