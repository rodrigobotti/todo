defmodule Todo.Server do
  use Agent, restart: :temporary

  alias Todo.Database, as: DB

  # Api

  def start_link(name) do
    Agent.start_link(
      fn ->
        IO.puts("Starting to-do server for #{name}")
        {name, DB.get(name) || Todo.List.new()}
      end,
      name: via_tuple(name)
    )
  end

  def add_entry(pid, entry) do
    Agent.cast(pid, fn {name, %Todo.List{} = list} ->
      new_list = Todo.List.add_entry(list, entry)
      DB.store(name, new_list)
      {name, new_list}
    end)
  end

  def entries(pid, date) do
    Agent.get(pid, fn {_name, %Todo.List{} = list} ->
      Todo.List.entries(list, date)
    end)
  end

  def entries(pid) do
    Agent.get(pid, fn {_name, %Todo.List{} = list} ->
      Todo.List.entries(list)
    end)
  end

  def update_entry(pid, entry) do
    Agent.cast(pid, fn {name, %Todo.List{} = list} ->
      new_list = Todo.List.update_entry(list, entry)
      DB.store(name, new_list)
      {name, new_list}
    end)
  end

  def delete_entry(pid, entry_id) do
    Agent.cast(pid, fn {name, %Todo.List{} = list} ->
      new_list = Todo.List.delete_entry(list, entry_id)
      DB.store(name, new_list)
      {name, new_list}
    end)
  end

  # Private

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

end
