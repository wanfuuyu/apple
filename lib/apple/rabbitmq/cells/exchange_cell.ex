defmodule Apple.Cell.Rabbitmq.ExchangeCell do
  use Kino.JS, assets_path: "lib/assets/rabbitmq/exchange_cell/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Rabbitmq Exchange"

  alias Apple.Rabbitmq

  @default_exchange_type "direct"

  @exchange_type_options [
    "direct",
    "topic",
    "fanout"
  ]

  @impl true
  def init(attrs, ctx) do
    # livebook connect to node

    ctx =
      assign(ctx,
        exchange_name: attrs[:exchange_name] || "",
        exchange_type: attrs[:exchange_type] || @default_exchange_type,
        queues: attrs[:queues] || [],
        exchange_type_options: @exchange_type_options
      )

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    # browser refresh

    payload = %{
      exchange_name: ctx.assigns.exchange_name,
      exchange_type: ctx.assigns.exchange_type,
      queues: ctx.assigns.queues
    }

    {:ok, payload, ctx}
  end

  @impl true
  def to_source(attrs) do
    # this is the entry, finally running elixir code
    attrs |> to_quoted() |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("update_exchange_name", exchange_name, ctx) do
    ctx = assign(ctx, exchange_name: exchange_name)
    broadcast_event(ctx, "update_exchange_name", exchange_name)
    {:noreply, ctx}
  end

  def handle_event("update_exchange_type", exchange_type, ctx) do
    ctx = assign(ctx, exchange_type: exchange_type)
    broadcast_event(ctx, "update_exchange_type", exchange_type)
    {:noreply, ctx}
  end

  @default_routing_key ""
  def handle_event("add_queue", _payload, ctx) do
    queues = ctx.assigns.queues
    queue_name = "00#{length(queues)}"

    new_queue = %{:name => queue_name, :routing_key => @default_routing_key}
    updated_queues = queues ++ [new_queue]
    ctx = assign(ctx, queues: updated_queues)
    broadcast_event(ctx, "set_queues", updated_queues)
    {:noreply, ctx}
  end

  def handle_event(
        "update_queue_name",
        %{"name" => new_name, "index" => index},
        ctx
      ) do
    updated_queues =
      Enum.with_index(ctx.assigns.queues)
      |> Enum.map(fn
        # 只修改第二个元素
        {%{name: _name} = item, idx} when idx == index -> %{item | name: new_name}
        # 其他元素保持不变
        {item, _} -> item
      end)

    ctx = assign(ctx, queues: updated_queues)
    broadcast_event(ctx, "set_queues", updated_queues)
    {:noreply, ctx}
  end

  def handle_event(
        "update_queue_routing_key",
        %{"routing_key" => routing_key, "index" => index},
        ctx
      ) do
    updated_queues =
      Enum.with_index(ctx.assigns.queues)
      |> Enum.map(fn
        # 只修改第二个元素
        {%{routing_key: _} = item, idx} when idx == index -> %{item | routing_key: routing_key}
        # 其他元素保持不变
        {item, _} -> item
      end)

    ctx = assign(ctx, queues: updated_queues)
    broadcast_event(ctx, "set_queues", updated_queues)
    {:noreply, ctx}
  end

  def handle_event("remove_queue", index, ctx) do
    # need to know index
    queues = ctx.assigns.queues
    updated_queues = List.delete_at(queues, index)
    ctx = assign(ctx, queues: updated_queues)
    broadcast_event(ctx, "set_queues", updated_queues)
    {:noreply, ctx}
  end

  # key is atom
  @inner_api ""
  @default_keys [:exchange_type, :exchange_name, :queues]
  @impl true
  def to_attrs(%{assigns: assigns}) do
    Map.take(assigns, @default_keys)
  end

  defp to_quoted(
         %{:exchange_type => exchange_type} =
           attrs
       ) do
    # create exchange and one queue
    IO.inspect(attrs)

    quote do
      queues = unquote(attrs[:queues])
      {:ok, url} = Rabbitmq.connection_url()
      {:ok, conn} = url |> AMQP.Connection.open()
      {:ok, channel} = conn |> AMQP.Channel.open()

      exchange_name = unquote(attrs[:exchange_name])
      exchange_type = unquote(exchange_type)

      # delete first

      Rabbitmq.delete_obj(unquote(@inner_api), :exchange, exchange_name)

      # delete queue
      {:ok, old_queues} = Rabbitmq.get_obj("", :exchange_binding_queues, exchange_name)

      Enum.each(old_queues, fn q ->
        Rabbitmq.delete_obj("", :queue, q["name"])
      end)

      case exchange_type do
        "direct" ->
          :ok = AMQP.Exchange.direct(channel, exchange_name)

        "topic" ->
          :ok = AMQP.Exchange.topic(channel, exchange_name)

        "fanout" ->
          :ok = AMQP.Exchange.fanout(channel, exchange_name)
      end

      Enum.each(queues, fn queue ->
        queue_name =
          "#{exchange_name}_#{exchange_type}_#{queue[:name]}"

        {:ok, _} = AMQP.Queue.declare(channel, queue_name, durable: true)

        binding_key =
          case queue do
            %{:routing_key => r_key} -> r_key
            _ -> raise "queue does not have a routing_key"
          end

        :ok =
          AMQP.Queue.bind(channel, queue_name, exchange_name, routing_key: binding_key)
      end)

      # release channel
      :ok = AMQP.Channel.close(channel)
    end
  end
end
