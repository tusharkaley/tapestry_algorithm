

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
  id_to_pid = Tapestryclasses.Utils.add_children(Tapestryclasses.Node, num_nodes, self())

  IO.inspect(id_to_pid)
  IO.puts("The number of children is #{inspect Supervisor.count_children(Tapestryclasses.Supervisor)}")
rescue
	e in ArgumentError ->  e
	System.stop(1)
end
