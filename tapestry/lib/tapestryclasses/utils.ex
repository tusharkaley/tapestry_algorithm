defmodule Tapestryclasses.Utils do
  	@doc """
		Function to get the child Spec for the workers
	"""
	def add_children(child_class, num_nodes, script_pid) do
		Enum.each 1..num_nodes, fn(x) ->
        {:ok, _child} = Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => x, :start => {child_class, :start_link, [x]}, :restart => :transient,:type => :worker})
	  end
		Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => :tracker, :start => {Tapestryclasses.Aggregator, :start_link, [script_pid]}, :restart => :transient,:type => :worker})
	end
end
