defmodule Apple.Rabbitmq.Cluster do
  use GenServer

  def start_link(options \\ []) do
    Testcontainers.start_link()

    GenServer.start_link(
      __MODULE__,
      options,
      name: Keyword.get(options, :name, __MODULE__)
    )
  end

  @impl true
  def init(_options \\ []) do
    {:ok, []}
  end

  def is_running() do
    GenServer.whereis(__MODULE__) != nil
  end

  def connection_url(name \\ __MODULE__) do
    GenServer.call(name, :get_connection_url)
  end
end
