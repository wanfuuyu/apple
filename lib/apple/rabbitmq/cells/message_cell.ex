defmodule Apple.Cell.Rabbitmq.MessageCell do
  use Kino.JS, assets_path: "lib/assets/rabbitmq/message_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Rabbitmq Message"

  alias Apple.Rabbitmq

  @default_message "Hello Rabbitmq"

  @doc """
  an exchange selector and a code area to edit message with a time input option
  """

  @impl true
  def init(_attrs, ctx) do
    # exchange_name should get from rabbitmq

    ctx =
      assign(ctx,
        exchanges: [],
        exchange_name: "",
        routing_key: "key1",
        send_times: 1000
      )

    {:ok, ctx, editor: [attribute: "message", language: "text", default_source: @default_message]}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      exchanges: ctx.assigns.exchanges,
      exchange_name: ctx.assigns.exchange_name,
      routing_key: ctx.assigns.routing_key,
      send_times: ctx.assigns.send_times
    }

    {:ok, payload, ctx}
  end

  @impl true
  def scan_binding(pid, _binding, _env) do
    send(pid, {:exchanges})
  end

  @impl true
  def handle_info({:exchanges}, ctx) do
    exchanges = exchange_names()

    exchange_name =
      case length(exchanges) do
        0 -> ""
        _ -> Enum.at(exchanges, 0)
      end

    broadcast_event(ctx, "exchanges", %{
      "exchange_name" => exchange_name,
      "exchanges" => exchanges
    })

    {:noreply,
     assign(ctx,
       exchanges: exchanges,
       exchange_name: exchange_name
     )}
  end

  @impl true
  def to_source(attrs) do
    attrs |> to_quited() |> Kino.SmartCell.quoted_to_string()
  end

  @default_keys [:exchange_name, :send_times, "message", :routing_key]
  @impl true
  def to_attrs(ctx) do
    Map.take(ctx.assigns, @default_keys)
  end

  @impl true
  def handle_event("update_send_times", send_times, ctx) do
    ctx = assign(ctx, send_times: send_times |> String.to_integer())
    broadcast_event(ctx, "update_send_times", send_times)
    {:noreply, ctx}
  end

  def handle_event("update_exchange_name", exchange_name, ctx) do
    ctx = assign(ctx, exchange_name: exchange_name)
    broadcast_event(ctx, "update_exchange_name", exchange_name)
    {:noreply, ctx}
  end

  def handle_event("update_routing_key", routing_key, ctx) do
    ctx = assign(ctx, routing_key: routing_key)
    broadcast_event(ctx, "update_routing_key", routing_key)
    {:noreply, ctx}
  end

  defp to_quited(attrs) do
    # get channel
    # send message to exchange
    # close channel
    quote do
      {:ok, connection_url} = Rabbitmq.connection_url()
      {:ok, conn} = AMQP.Connection.open(connection_url)
      {:ok, channel} = conn |> AMQP.Channel.open()
      exchange_name = unquote(attrs[:exchange_name])
      send_times = unquote(attrs[:send_times])
      message = unquote(attrs["message"])
      routing_key = unquote(attrs[:routing_key])

      Enum.each(1..send_times, fn _ ->
        AMQP.Basic.publish(channel, exchange_name, routing_key, message)
      end)

      AMQP.Channel.close(channel)
    end
  end

  def list_exchanges do
    case Rabbitmq.list_obj("", :exchanges) do
      {:ok, exchanges} ->
        filtered_exchanges =
          Enum.filter(exchanges, fn exchange ->
            exchange["user_who_performed_action"] != "rmq-internal"
          end)

        filtered_exchanges

      {_, msg} ->
        IO.inspect("not ready #{msg} ")
        []
    end
  end

  defp exchange_names do
    exs = list_exchanges()
    Enum.map(exs, fn map -> map["name"] end)
  end
end
