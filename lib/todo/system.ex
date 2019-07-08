defmodule Todo.System do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [
      Todo.Metrics,
      Todo.ProcessRegistry,
      Todo.Database,
      Todo.Cache,
      Todo.Web
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

end
