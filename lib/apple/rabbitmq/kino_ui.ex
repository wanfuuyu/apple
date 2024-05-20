defmodule Apple.Rabbitmq.KinoUI do
  alias Apple.Rabbitmq
  alias VegaLite, as: Vl

  defp inner_consume(channel, num, current) when current < num do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts(" [x] Received #{payload}")
        AMQP.Basic.ack(channel, meta.delivery_tag)
        inner_consume(channel, num, current + 1)
    after
      5000 ->
        IO.puts("No message in 5 seconds")
        :ok
    end
  end

  defp inner_consume(_channel, _num, _current) do
    :ok
  end

  defp consume(%{:prefetch => prefetch, :num => num, :queue => queue, :quit => quit}) do
    consumer_pid = nil

    {:ok, connection_url} = Rabbitmq.connection_url()
    {:ok, conn} = AMQP.Connection.open(connection_url)

    {:ok, channel} = conn |> AMQP.Channel.open()
    AMQP.Basic.qos(channel, prefetch_count: prefetch)
    AMQP.Basic.consume(channel, queue, consumer_pid)

    inner_consume(channel, num, 0)

    case quit do
      true ->
        AMQP.Connection.close(conn)
        :ok

      _ ->
        :ok
    end
  end

  def consume_form(exchange_name) do
    {:ok, queues} = Rabbitmq.get_obj("", :exchange_binding_queues, exchange_name)

    names =
      Enum.map(queues, fn queue ->
        {queue["name"], queue["name"]}
      end)

    form =
      Kino.Control.form(
        [
          queue: Kino.Input.select("queue", names),
          prefetch: Kino.Input.number("prefetch"),
          num: Kino.Input.number("消费数量"),
          quit: Kino.Input.checkbox("结束后断开")
        ],
        submit: "消费"
      )

    Kino.listen(form, fn event ->
      consume(event.data)
    end)

    form
  end

  @doc """
  name is module
  """
  def exchange_queue_plot(exchange_name, metric_name \\ "messages") do
    {:ok, queues} = Rabbitmq.get_obj("", :exchange_binding_queues, exchange_name)

    message_plot =
      Vl.new(width: 300, height: 200, padding: 20)
      |> Vl.repeat(
        [
          layer:
            Enum.map(queues, fn queue ->
              queue["name"]
            end)
        ],
        Vl.new()
        |> Vl.mark(:line)
        |> Vl.encode_field(:x, "iter", type: :quantitative, title: "Measurement")
        |> Vl.encode_repeat(:y, :layer, type: :quantitative, title: "Messages")
        |> Vl.encode(:color, datum: [repeat: :layer], type: :nominal)
      )
      |> Kino.VegaLite.new()

    Kino.listen(200, fn i ->
      {:ok, queues} = Rabbitmq.get_obj("", :exchange_binding_queues, exchange_name)

      name_messages_map =
        Map.new(
          Enum.map(queues, fn item ->
            {item["name"], item[metric_name]}
          end)
        )

      point =
        name_messages_map
        |> Map.new()
        |> Map.put(:iter, i)

      Kino.VegaLite.push(message_plot, point, window: 400)
    end)

    message_plot
  end
end
