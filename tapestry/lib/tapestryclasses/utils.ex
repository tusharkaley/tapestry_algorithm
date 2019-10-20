defmodule Tapestryclasses.Utils do
  	@doc """
		Function to get the child Spec for the workers
	"""
	def add_children(child_class, num_nodes, script_pid) do

    map = Enum.reduce 1..num_nodes, %{}, fn x, acc ->

      # Generating SHA1 for the index
      sha_id = :crypto.hash(:sha, to_string(x)) |> Base.encode16
      # Slicing out the lest significant 8 digits and checking for collisions
      sha_id = if Map.has_key?(acc, String.slice(sha_id, -8, 8)) do
          # Moving over the slicing window by 1 so as to avoid collisions
          String.slice(sha_id, -9, 8)
        else
          # No collisions FTW
          String.slice(sha_id, -8, 8)
        end
      {:ok, child} = Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => sha_id, :start => {child_class, :start_link, [x]}, :restart => :transient,:type => :worker})

      Map.put(acc, sha_id, child)
    end
    IO.inspect(map)
    # Enum.each 1..num_nodes, fn(x) ->


	  # end
		Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => :aggregator, :start => {Tapestryclasses.Aggregator, :start_link, [script_pid]}, :restart => :transient,:type => :worker})
	end

end
