defmodule Tapestryclasses.Aggregator do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: :aggregator])
  end
  def collect_hops(hops, source) do
    GenServer.cast(:aggregator, {:log_hops, hops, source})
  end

  def init(_init_args) do
    node_state = %{max_hops: 0, dest_addr: nil}
    {:ok, node_state}
  end

  def handle_cast({:log_hops, hops, source}, node_state) do
    state_hops = node_state.max_hops
    node_state = if state_hops < hops do
                  node_state = Map.put(node_state, :max_hops, hops)
                  Map.put(node_state, :dest_addr, source)
                else
                  node_state
                end
    IO.inspect(node_state)

  end
end
