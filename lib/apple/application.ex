defmodule Apple.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(Apple.Cell.Rabbitmq.ExchangeCell)
    Kino.SmartCell.register(Apple.Cell.Rabbitmq.MessageCell)

    children = []

    opts = [strategy: :one_for_one, name: Apple.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
