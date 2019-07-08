defmodule Todo.Server do
  use GenServer, restart: :temporary

  alias Todo.Database, as: DB

  # Api

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: global_name(name))
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def entries(pid) do
    GenServer.call(pid, {:entries})
  end

  def update_entry(pid, entry) do
    GenServer.cast(pid, {:update_entry, entry})
  end

  def delete_entry(pid, entry_id) do
    GenServer.cast(pid, {:delete_entry, entry_id})
  end

  def whereis(name) do
    case :global.whereis_name({__MODULE__, name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  # Server

  @impl GenServer
  def init(name) do
    IO.puts("Starting to-do server for #{name}")
    send(self(), :long_running_init)
    {:ok, {name, nil}, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_info(:long_running_init, {name, _list}) do
    {:noreply, {name, DB.get(name) || Todo.List.new()}, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_info(:timeout, {name, list}) do
    IO.puts("Stopping to-do server for #{name}")
    {:stop, :normal, {name, list}}
  end

  @impl GenServer
  def handle_call({:entries}, _from, {_name, %Todo.List{} = list} = state) do
    {:reply, Todo.List.entries(list), state, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {_name, %Todo.List{} = list} = state) do
    {:reply, Todo.List.entries(list, date), state, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, %Todo.List{} = list}) do
    new_list = Todo.List.add_entry(list, entry)
    DB.store(name, new_list)
    {:noreply, {name, new_list}, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_cast({:update_entry, entry}, {name, %Todo.List{} = list}) do
    new_list = Todo.List.update_entry(list, entry)
    DB.store(name, new_list)
    {:noreply, {name, new_list}, expiry_idle_timeout()}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {name, %Todo.List{} = list}) do
    new_list = Todo.List.delete_entry(list, entry_id)
    DB.store(name, new_list)
    {:noreply, {name, new_list}, expiry_idle_timeout()}
  end

  # Private

  defp global_name(name) do
    {:global, {__MODULE__, name}}
  end

  defp expiry_idle_timeout(), do: Application.fetch_env!(:todo, :todo_item_expiry)
end
