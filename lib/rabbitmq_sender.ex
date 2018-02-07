defmodule RabbitMQSender do
  use GenServer

  defstruct [:connection, :channel]

  # API

  def resl(prompt, sender_pid, queue) do
    input = IO.gets("#{prompt}: ") |> String.trim
    sender_pid |> RabbitMQSender.send_message(queue, input)
    resl prompt, sender_pid, queue
  end

  def start_link(options \\ [], gen_server_options \\ []) do
    rabbit_options =
      case options do
        [] -> get_rabbit_options()
        _ -> options
      end
    GenServer.start_link RabbitMQSender, [rabbit_options], gen_server_options
  end
  @moduledoc """
  Documentation for RabbitMQSender.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RabbitMQSender.hello
      :world

  """
  def hello do
    :world
  end

  def get_rabbit_options do
    Application.get_env(:rabbitmq_sender, :rabbit_options, [])
  end

  def send_message(server, queue, message, send_sync \\ false) do
    if send_sync do
      server |> GenServer.call({:send_message, queue, message})
    else
      server |> GenServer.cast({:send_message, queue, message})
    end
  end

  # Callbacks
  def init([rabbit_options]) do
    {:ok, connection} = AMQP.Connection.open(rabbit_options)
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, %RabbitMQSender{connection: connection, channel: channel}}
  end

  def handle_cast({:send_message, queue, message}, %RabbitMQSender{channel: channel} = state) do
    send_message_to_queue(channel, queue, message)
    IO.puts "Message #{message} has been sent to #{queue}"
    {:noreply, state}
  end

  def handle_call({:send_message, queue, message}, _from, %RabbitMQSender{channel: channel} = state) do
    send_message_to_queue(channel, queue, message)
    IO.puts "Message #{message} has been sent to #{queue}"
    {:reply, :ok, state}
  end

  # Helpers
  defp send_message_to_queue(channel, queue, message) do
    AMQP.Queue.declare(channel, queue)
    AMQP.Basic.publish(channel, "", queue, message)
  end
end
