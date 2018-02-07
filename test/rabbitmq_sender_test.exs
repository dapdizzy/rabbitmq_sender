defmodule RabbitMQSenderTest do
  use ExUnit.Case
  doctest RabbitMQSender

  test "greets the world" do
    assert RabbitMQSender.hello() == :world
  end
end
