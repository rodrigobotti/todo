defmodule Todo.Metrics do
  # to inject the child_spec of task which calls :start_link
  use Task

  def start_link(_) do
    IO.puts("Starting metrics collector")
    Task.start_link(&loop/0)
  end

  defp loop do
    Process.sleep(:timer.seconds(10))
    IO.inspect(collect_metrics())
    loop()
  end

  defp collect_metrics do
    [
      memory_usage: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count)
    ]
  end
end
