import Supervisor.Spec

defmodule Tapestryclasses.Supervisor do
	use Supervisor

	require Logger
@moduledoc """
This is the Supervisor for the Vampire Numbers project
"""
		@doc """
		Client function which triggers the Supervisor start
		"""
		def start_link() do
			Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
		end

    def init(_nums_range) do

			supervise([], strategy: :one_for_one)

		end

end
