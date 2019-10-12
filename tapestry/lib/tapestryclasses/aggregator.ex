defmodule Tapestryclasses.Aggregator do
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, [init_arg], [name: :aggregator])
  end

  def init(init_arg) do
    {:ok, init_arg}
  end
end
