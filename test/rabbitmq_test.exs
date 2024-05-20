defmodule AppleTest do
  use ExUnit.Case
  doctest Apple

  test "greets the world" do
    Apple.Rabbitmq.start_link()
    assert Rabbitmq.hello() == :world
  end
end
