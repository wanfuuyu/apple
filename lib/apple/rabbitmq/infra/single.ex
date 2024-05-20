defmodule Apple.Rabbitmq.Single do
  use GenServer

  alias Testcontainers.Connection
  alias Testcontainers.RabbitMQContainer

  @rabbitmq_image "rabbitmq:3.13-management"

  def start_link(options \\ []) do
    Testcontainers.start_link()

    GenServer.start_link(
      __MODULE__,
      options,
      name: Keyword.get(options, :name, __MODULE__)
    )
  end

  @impl true
  def init(options \\ []) do
    setup(options)
  end

  defp setup(options) do
    config =
      RabbitMQContainer.new()
      |> RabbitMQContainer.with_image(@rabbitmq_image)

    {:ok, container} = Testcontainers.start_container(config)

    {conn, _} = Connection.get_connection(options)

    {
      :ok,
      %{
        docker_conn: conn,
        id: container.container_id,
        ip: container.ip_address,
        amqp: RabbitMQContainer.connection_url(container),
        management_api: "http://#{container.ip_address}:15672/api",
        vhost: "/"
      }
    }
  end

  def is_running() do
    GenServer.whereis(__MODULE__) != nil
  end

  def api(name \\ __MODULE__) do
    GenServer.call(name, :get_api_endpoint)
  end

  def connection_url(name \\ __MODULE__) do
    GenServer.call(name, :get_connection_url)
  end

  def attach(name \\ __MODULE__) do
    GenServer.call(name, :attach)
  end

  def run(cmd, name \\ __MODULE__) do
    GenServer.call(name, {:run, cmd})
  end

  @impl true
  def handle_call(:get_connection_url, _from, state) do
    {:reply, state.amqp, state}
  end

  @impl true
  def handle_call(:get_api_endpoint, _from, state) do
    {:reply, state.management_api, state}
  end

  @impl true
  def handle_call(:attach, _from, state) do
    node = attach_node(state.ip, state.id)
    {:reply, node, state}
  end

  @impl true
  def handle_call({:run, cmd}, _from, state) do
    output = run_command(state.id, cmd)
    {:reply, output, state}
  end

  defp attach_node(container_ip, container_id) do
    container = fetch_beam_node(container_id)
    # hosts
    add_host(container_ip, container.host)

    rabbitmq_node = String.to_atom(container.node)
    Node.set_cookie(rabbitmq_node, String.to_atom(container.cookie))

    true = Node.connect(rabbitmq_node)

    rabbitmq_node
  end

  @cookie_command "cat /var/lib/rabbitmq/.erlang.cookie"
  @nodename_command "rabbitmqctl status | grep \"Node name\" | awk '{printf $3}'"
  defp fetch_beam_node(container_id) do
    node_cookie =
      run_command(
        container_id,
        @cookie_command
      )

    node_name =
      run_command(
        container_id,
        @nodename_command
      )

    [_, host] = String.split(node_name, "@")

    %{
      node: node_name,
      cookie: node_cookie,
      host: host
    }
  end

  defp run_command(container_id, raw_command) do
    command = """
    docker exec -i #{container_id} #{raw_command}
    """

    {result, _} = System.cmd("bash", ["-c", command])

    result
  end

  @hostfile "/etc/hosts"

  def add_host(ip, hostname) do
    new_entry = "#{ip} #{hostname}\n"

    case File.read(@hostfile) do
      {:ok, content} ->
        lines = String.split(content, "\n")

        new_lines =
          Enum.filter(lines, fn line ->
            !String.contains?(line, hostname)
          end)

        new_content = Enum.join(new_lines, "\n") <> new_entry

        File.write("/etc/hosts", new_content)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
