defmodule Tapestryclasses.Utils do
  	@doc """
		Function to get the child Spec for the workers
	"""
	def add_children(child_class, num_requests, num_nodes, script_pid) do

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
      {:ok, child} = Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => sha_id, :start => {child_class, :start_link, []}, :restart => :transient,:type => :worker})

      Map.put(acc, sha_id, child)
    end

    total_messages = num_requests* num_nodes
    {:ok, _agg} = Supervisor.start_child(Tapestryclasses.Supervisor, %{:id => :aggregator, :start => {Tapestryclasses.Aggregator, :start_link, [total_messages, script_pid, num_nodes]}, :restart => :transient,:type => :worker})
    map

  end

  def get_guid(pid) do
    [head| _tail] = :ets.lookup(:pid_id_mapping, "pid_to_id")
    pid_to_id = elem(head, 1)
    guid = Map.get(pid_to_id, pid)
    guid
  end

  def get_pid(guid) do
    [head| _tail] = :ets.lookup(:id_pid_mapping, "id_to_pid")
    id_to_pid = elem(head, 1)
    pid = Map.get(id_to_pid, guid)
    pid
  end

  def set_id_pid_table(id_to_pid, pid_to_id) do
    :ets.new(:id_pid_mapping, [:named_table, read_concurrency: true])
    :ets.insert(:id_pid_mapping, {"id_to_pid", id_to_pid})

    :ets.new(:pid_id_mapping, [:named_table, read_concurrency: true])
    :ets.insert(:pid_id_mapping, {"pid_to_id", pid_to_id})
    IO.puts("Set pid_to_id table in ets")

  end
end
