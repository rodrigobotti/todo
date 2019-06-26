defmodule Todo.Server do
  use GenServer

  # Api

  def start() do
    GenServer.start(__MODULE__, nil)
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

  # Server

  @impl GenServer
  def init(_init_arg) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_call({:entries}, _from, %Todo.List{} = state) do
    {:reply, Todo.List.entries(state), state}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, %Todo.List{} = state) do
    {:reply, Todo.List.entries(state, date), state}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, %Todo.List{} = state) do
    {:noreply, Todo.List.add_entry(state, entry)}
  end

  @impl GenServer
  def handle_cast({:update_entry, entry}, %Todo.List{} = state) do
    {:noreply, Todo.List.update_entry(state, entry)}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, %Todo.List{} = state) do
    {:noreply, Todo.List.delete_entry(state, entry_id)}
  end
end
