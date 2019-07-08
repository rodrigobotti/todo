defmodule Todo.Database do
  @db_folder "./persist"
  @pool_size 3

  def store(key, data) do
    # asks pool for a single worker
    :poolboy.transaction(
      __MODULE__,
      # invoked when worker is available
      # once the lambda finishes, the worker is returned to the pool
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_id ->
        Todo.DatabaseWorker.get(worker_id, key)
      end
    )
  end

  def child_spec(_) do
    File.mkdir_p!(@db_folder)

    :poolboy.child_spec(
      __MODULE__, # child id
      # pool options
      [
        name: {:local, __MODULE__}, # pool manager locally registered
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      [folder: @db_folder] # worker arguments passed to start_link
    )
  end
end
