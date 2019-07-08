defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      &add_entry(&2, &1)
    )
  end

  def size(todo_list) do
    map_size(todo_list.entries)
  end

  def add_entry(
        %Todo.List{auto_id: id, entries: entries} = todo_list,
        %{date: _date, title: _title} = entry
      ) do
    entry = Map.put(entry, :id, id)
    new_entries = Map.put(entries, id, entry)
    %Todo.List{todo_list | auto_id: id + 1, entries: new_entries}
  end

  def entries(%Todo.List{entries: entries}, date) do
    entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def entries(%Todo.List{entries: entries}) do
    entries
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(%Todo.List{entries: entries} = todo_list, entry_id, updater_fn) do
    case Map.fetch(entries, entry_id) do
      :error ->
        todo_list

      {:ok, entry} ->
        entry_id = entry.id
        new_entry = %{id: ^entry_id, date: _date, title: _title} = updater_fn.(entry)
        new_entries = Map.put(entries, entry_id, new_entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, new_entry = %{id: id, date: _date, title: _title}) do
    update_entry(todo_list, id, fn _old_entry -> new_entry end)
  end

  def delete_entry(%Todo.List{entries: entries} = todo_list, entry_id)
      when is_integer(entry_id) and entry_id > 0 do
    new_entries = Map.delete(entries, entry_id)
    %Todo.List{todo_list | entries: new_entries}
  end

  defimpl String.Chars, for: TodoList do
    def to_string(todo_list) do
      "#TodoList[#{map_size(todo_list.entries)}]"
    end
  end

  defimpl Collectable, for: TodoList do
    def into(original) do
      {original, &into_callback/2}
    end

    defp into_callback(todo_list, {:cont, entry}) do
      Todo.List.add_entry(todo_list, entry)
    end

    defp into_callback(todo_list, :done), do: todo_list
    defp into_callback(_todo_list, :halt), do: :ok
  end
end
