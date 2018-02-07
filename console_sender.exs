{:ok, pid} = RabbitMQSender.start_link

queue_name = IO.gets("Enter queue name: ") |> String.trim

RabbitMQSender.resl "Enter message", pid, queue_name
