defmodule Todo.Database do
  use GenServer

  alias Todo.DatabaseWorker, as: Worker

  @db_folder "./persist"
  @pool_size 3

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)
    worker_pool = spawn_workers()
    {:ok, worker_pool}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, worker_pool) do
    worker_pid = choose_worker(worker_pool, key)
    Worker.store(worker_pid, key, data)
    {:noreply, worker_pool}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, worker_pool) do
    worker_pid = choose_worker(worker_pool, key)
    data = Worker.get(worker_pid, key)
    {:reply, data, worker_pool}
  end

  def choose_worker(worker_pool, key) do
    index = :erlang.phash2(to_string(key), @pool_size)
    Map.get(worker_pool, index)
  end

  def spawn_workers do
    0..(@pool_size - 1)
    |> Enum.reduce(%{}, fn index, map ->
      {:ok, worker_pid} = Worker.start(@db_folder)
      Map.put(map, index, worker_pid)
    end)
  end
end
