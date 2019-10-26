defmodule Tapestryclasses.Node do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_init_arg) do
    node_state = %{"message" => nil,"routingTable" => nil}
    {:ok, node_state}
  end
  @doc """
    Client side function to send the first message
  """
  def send_first_message(pid, destination, message) do
    GenServer.cast(pid, {:send_first_message, destination, message})
  end
  @doc """
  Client side function to trigger the creation of routing tables of the node
  """
  # @spec update_state(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  def update_state(pid) do
    GenServer.cast(pid, {:update_state})
  end
  @doc """
    Client side function to receive a message
  """
  def receive_message(pid, message, last_hop, destination_addr) do
    GenServer.cast(pid, {:receive_message, message, last_hop, destination_addr})
  end

  @doc """
   Client side function to add new node to the network
  """
  def update_routing(pid,newNode_guid) do
    GenServer.cast(pid, {:add_node,newNode_guid})
  end

  @doc """
    Add new node to network
  """
  def handle_cast({:add_node,newNode_guid}, node_state) do
    self_id = Tapestryclasses.Utils.get_guid(self())
    routingTable = Map.get node_state, "routingTable"
    pos = mismatchPosition self_id, newNode_guid, 0
    val = String.at newNode_guid, pos
    tup = {pos+1,val}
    # Logger.error("Inside add node")
    routingTable = if Map.has_key? routingTable,tup do
      entry_add= findCloser(Map.get(routingTable,tup), newNode_guid, self_id)
      Map.put_new routingTable, tup, entry_add
    else
      Map.put_new routingTable, tup,newNode_guid
    end
    node_state = Map.put node_state, "routingTable", routingTable
    {:noreply, node_state}

  end

 @doc """
  Server side function to handle what happens when a message is received
 """
  def handle_cast({:receive_message, message, last_hop, destination_addr}, node_state) do
    # from self() PID get my GUID and see if there is a match with the destination addr then
    # you have reached so send message to aggregator
    # Logger.debug("Received message for destination #{destination_addr}, lastHop #{last_hop}")
    self_id = Tapestryclasses.Utils.get_guid(self())
    if self_id == destination_addr do
      # You have reached the destination...Notify the Aggregator
      # Logger.debug("Destination reached in #{last_hop} hops")
      Tapestryclasses.Aggregator.collect_hops(last_hop, self())
    else
    # Logger.debug("Inside receive message")
    routingTable = Map.get node_state, "routingTable"
    pos = mismatchPosition(self_id,destination_addr,0)
    levelHop = max(pos,last_hop) +1
    val = String.at destination_addr,levelHop-1
    tup = {levelHop,val}

    if Map.has_key? routingTable,tup do
      next_hop_addr = Map.get routingTable, tup
     next_pid = Tapestryclasses.Utils.get_pid(next_hop_addr)
    # Logger.debug("Sending message to #{next_hop_addr}, for #{destination_addr}, hoplevel #{levelHop}")

    Tapestryclasses.Node.receive_message(next_pid, message, levelHop, destination_addr)
    else
      IO.puts "Oops: Entry not found! levelhop #{levelHop}, dest #{destination_addr}, tup #{inspect tup}, table #{inspect routingTable}"

    end
    end

    {:noreply, node_state}
  end

@doc """
  Server side function to send the first message from this node
"""
  def handle_cast({:send_first_message, destination, message}, node_state) do

    #New logic to send first message
    routingTable = Map.get node_state, "routingTable"
    guid = Tapestryclasses.Utils.get_guid(self())
    pos = mismatchPosition(destination,guid,0)
    val = String.at(destination,pos)
    levelHop = pos+1
    tup = {levelHop, val}
    next_hop_addr = Map.get routingTable, tup

    next_pid = Tapestryclasses.Utils.get_pid(next_hop_addr)
    # Logger.debug("First message being sent to #{next_hop_addr}  for  #{destination}, from #{guid}")
    Tapestryclasses.Node.receive_message(next_pid, message, levelHop, destination)
    {:noreply, node_state}
  end

@doc """
  Server side function to create the routing table for the node and
  update it in the state
"""
  def handle_cast({:update_state}, node_state) do
    # Logger.debug("Creating routing table for #{inspect self()}")
    me = Tapestryclasses.Utils.get_guid(self())
    [head| _tail] = :ets.lookup(:pid_id_mapping, "pid_to_id")
    pid_to_id = elem(head, 1)
    list = Map.values pid_to_id
    list = List.delete list, me
    map = Enum.reduce list, %{}, fn x, acc ->
      pos = mismatchPosition(me,x,0)
      val = String.at(x,pos)
      tup = {pos+1, val}
      entry =
      if Map.has_key? acc, tup do
        findCloser(Map.get(acc,tup), x, me)
      else
        x
      end
      Map.put(acc, tup, entry)
    end

    node_state = Map.put node_state, "routingTable", map

    Tapestryclasses.Aggregator.routing_table_done()

    {:noreply, node_state}
  end
  def mismatchPosition(i,x,position) do
    if position < String.length x do
        mismatch =
        if String.at(i,position) != String.at(x,position) do
            position
        else
            mismatchPosition(i,x,position+1)
        end
      else
      position-1
    end
  end

  def findCloser(old,new,me) do
    me = List.first(Tuple.to_list(Integer.parse(me,16)))
    o = List.first(Tuple.to_list(Integer.parse(old,16)))
    n = List.first(Tuple.to_list(Integer.parse(new,16)))
    if abs(me- o) > abs(me- n) do
      new
    else
      old
    end
  end

end
