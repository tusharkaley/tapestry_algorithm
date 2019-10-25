
dynamic_num_nodes = 10
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

  start_time = Time.utc_now()
  IO.puts("Triggering creation of routing tables for #{num_nodes - dynamic_num_nodes} nodes.")
  IO.puts("Rest of the #{dynamic_num_nodes} will be added dynamically")
  #Remove k nodes, to be added later
  dynamic_nodes = Enum.take_random pids, dynamic_num_nodes

  pids = pids -- dynamic_nodes

  dynamicGuids =  Enum.reduce dynamic_nodes, [], fn (d_node, acc) ->
    dynamic_node_guid = Map.get pid_to_id, d_node
    [dynamic_node_guid | acc]
   end

  id_to_pid= Map.drop id_to_pid, dynamicGuids

  Enum.each(pids, fn x->
      Tapestryclasses.Node.update_state(x)
  end)

  receive do
    {:routing_tables_ready, _pid} -> IO.puts("Routing tables ready for #{num_nodes - dynamic_num_nodes} nodes. Can send messages now")
  end
  end_time = Time.utc_now()
  time_diff = Time.diff(end_time, start_time, :millisecond)
  IO.puts("Creation of routing tables takes #{time_diff} milliseconds")

  # The assumption here is that the routing tables are ready.
  # Maybe will have to give this some more thought

  # This is the code to send messages once the routing tables are ready
  #Add new node dynamically:
  Enum.each dynamic_nodes, fn d_node ->
   Tapestryclasses.Node.update_state(d_node)
  end

  #choose num dest and send mesages:

  message ="message"
  # len = length pids
  IO.puts("Started sending messages")
  sent = 0
  Tapestryclasses.Aggregator.send_in_the_clowns(dynamic_nodes, pids, pid_to_id)
  Enum.each(pids, fn x->
    x_guid = Map.get pid_to_id, x

    id_to_pid_temp = id_to_pid
    {_val, id_to_pid_temp} = Map.pop(id_to_pid_temp, x_guid)
    id_to_pid_temp = Map.keys(id_to_pid_temp)
    dest = Enum.take_random(id_to_pid_temp, num_requests)

    Enum.each(dest, fn y ->
      # IO.puts "Send message from #{x} to #{y}"
      Tapestryclasses.Node.send_first_message(x, y, message)
      # Process.sleep(10)
      # Send message to destination (y) from the source (x)
    end)

  end
  )
  #Send message from new nodes:
  Enum.each dynamic_nodes, fn d_node ->
    dynamic_node_guid = Map.get pid_to_id, d_node
    id_to_pid_temp = id_to_pid
    {_val, id_to_pid_temp} = Map.pop(id_to_pid_temp, dynamic_node_guid)

    id_to_pid_temp = Map.keys(id_to_pid_temp)
    dest = Enum.take_random(id_to_pid_temp, num_requests)

    Enum.each(dest, fn y ->
      # IO.puts "Send message from #{x} to #{y}"
      Tapestryclasses.Node.send_first_message(d_node, y, message)
      # Send message to destination (y) from the source (x)
    end)

  end


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
