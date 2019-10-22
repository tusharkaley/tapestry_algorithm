defmodule Tapestryclasses.Aggregator do
  use GenServer
  require Logger

  def start_link(total_nodes, script_pid, num_nodes) do
    GenServer.start_link(__MODULE__, [total_nodes, script_pid, num_nodes], [name: :aggregator])
  end
  @doc """
    Client side function to log the number of logs required to reach the destination
    and check if it is the max
  """
  def collect_hops(hops, source) do
    GenServer.cast(:aggregator, {:log_hops, hops, source})
  end
  @doc """
    Client side function to mark the creation of routing table
  """
  def routing_table_done() do
    GenServer.cast(:aggregator, {:routing_table})
  end
@doc """
  Init function to set the state of the genserver
"""
  def init(init_args) do
    {:ok, total_nodes} = Enum.fetch(init_args, 0)
    {:ok, script_pid} = Enum.fetch(init_args, 1)
    {:ok, num_nodes} = Enum.fetch(init_args, 2)
    node_state = %{"max_hops"=> 0, "dest_addr" => nil, "num_nodes_done" => 0, "total_nodes" => total_nodes, "terminate_addr"=> script_pid, "num_nodes"=> num_nodes, "num_nodes_rt"=> 0}
    {:ok, node_state}
  end
@doc """
  Server side function to log hops
"""
  def handle_cast({:log_hops, hops, source}, node_state) do
    state_hops = node_state["max_hops"]
    node_state = if state_hops < hops do
                  node_state = Map.put(node_state, "max_hops", hops)
                  Map.put(node_state, "dest_addr", source)
                else
                  node_state
                end
    node_state = Map.put(node_state, "num_nodes_done", node_state["num_nodes_done"] + 1)
    num_nodes_done = node_state["num_nodes_done"]
    if num_nodes_done == node_state["total_nodes"] do
      # Time to terminate
      IO.puts("Maximum hops: #{node_state.max_hops}")
      send(node_state["terminate_addr"], {:terminate_now, self()})
    end
    IO.inspect(node_state)

  end
@doc """
  Server side function to log creation of routing tables
  Once all routing tables are created we send a message to the calling script
"""
  def handle_cast({:routing_table}, node_state) do
    IO.inspect(node_state)
    num_nodes_rt = node_state["num_nodes_rt"] + 1
    node_state = Map.put(node_state, "num_nodes_rt", num_nodes_rt)
    Logger.debug("Num nodes done #{num_nodes_rt}")
    if num_nodes_rt == node_state["num_nodes"] do
      Logger.debug("All routing tables are ready")
      send(node_state["terminate_addr"], {:routing_tables_ready, self()})
    end
    {:noreply, node_state}
  end
end
