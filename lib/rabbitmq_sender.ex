defmodule RabbitMQSender do
  use GenServer

  defstruct [:connection, :channel, :exchange, :exchange_type, :rpc_mode, :reply_queue]

  # API

  def resl(prompt, sender_pid, queue) do
    input = IO.gets("#{prompt}: ") |> String.trim
    sender_pid |> RabbitMQSender.send_message(queue, input)
    resl prompt, sender_pid, queue
  end

  @doc """
   Starts linked RabbitMQSender rprocess and returns it's pid, or raises otherwise.
   option_switches - in a keyword list of options.
   Options include:
   :exchnage - name of the exchange to be configured,
   :exchange_type - type of the exchange, which include: :direct, :fanout, :topic, :match (and :headers),
   :rpc_mode - denotes whether to send messages with correlation_id specified in the metadata,
   :reply_queue - the name of the queue we should reply to in case we are operating in the :rpc_mode
   etc. (to be continued...)
  """
  def start_link(connection_options \\ [], gen_server_options \\ [], option_switches \\ []) do
    rabbit_connection_options =
      case connection_options do
        [] -> get_rabbit_connection_options()
        _ -> connection_options
      end
    GenServer.start_link RabbitMQSender, [rabbit_connection_options, option_switches], gen_server_options
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

  def get_rabbit_connection_options do
    Application.get_env(:rabbitmq_sender, :rabbit_options, [])
  end

  @doc """
  Send a message.
  Note: a queue plays a role of a topic in case we've configured a named Exchange with type :topic.
  Use options to provide some additional options for the message, like external (nto generated) correlation_id.
  """
  def send_message(server, queue, message, send_sync \\ false, options \\ []) do
    if send_sync do
      server |> GenServer.call({:send_message, queue, message, options})
    else
      server |> GenServer.cast({:send_message, queue, message, options})
    end
  end

  # Callbacks
  def init([rabbit_options, option_switches]) do
    {:ok, connection} = AMQP.Connection.open(rabbit_options)
    {:ok, channel} = AMQP.Channel.open(connection)
    exchange =
      with exchange_name when exchange_name |> is_binary() <- option_switches[:exchange] do
        AMQP.Exchange.declare(channel, exchange_name, option_switches[:exchange_type] || :direct)
        exchange_name
      end
    {:ok,
      %RabbitMQSender
      {
        connection: connection,
        channel: channel,
        exchange: exchange,
        exchange_type: option_switches[:exchange_type] || :direct,
        rpc_mode: (if option_switches[:rpc_mode], do: true, else: false),
        reply_queue: option_switches[:reply_queue]
      }
    }
  end

  def handle_cast({:send_message, queue, message, options}, %RabbitMQSender{channel: channel, exchange: exchange, rpc_mode: rpc_mode, reply_queue: reply_queue} = state) do
    send_message_to_queue(
      channel,
      queue,
      message,
      exchange,
      merge_options(
        (if rpc_mode, do: build_rpc_options(reply_queue, options[:correlation_id]), else: []),
        options)
      )
    IO.puts "Message #{message} has been sent to #{queue}"
    {:noreply, state}
  end

  def handle_call({:send_message, queue, message, options}, _from, %RabbitMQSender{channel: channel, exchange: exchange, rpc_mode: rpc_mode, reply_queue: reply_queue} = state) do
    result = send_message_to_queue(
      channel,
      queue,
      message,
      exchange,
      merge_options(
        (if rpc_mode, do: build_rpc_options(reply_queue, options[:correlation_id]), else: []),
        options)
      )
    IO.puts "Message #{message} has been sent to #{queue}"
    {:reply, (if rpc_mode, do: result, else: :ok), state}
  end

  # Helpers
  defp send_message_to_queue(channel, queue, message, exchange, options \\ []) do
    unless exchange do
      AMQP.Queue.declare(channel, queue)
    end
    AMQP.Basic.publish(channel, exchange || "", queue, message, options)
    with correlation_id when correlation_id |> is_binary() <- options[:correlation_id] do
      correlation_id
    end
  end

  defp gen_correlation_id() do
    correlation_id =
      :erlang.unique_integer
      |> :erlang.integer_to_binary
      |> Base.encode64
    correlation_id
  end

  defp build_rpc_options(reply_queue, correlation_id) do
    [
      correlation_id: correlation_id || gen_correlation_id(),
      reply_to: reply_queue
    ]
  end

  defp merge_options([], override_options) do
    override_options
  end

  defp merge_options(given_options, override_options) do
    given_options |> Keyword.merge(override_options)
  end
end
