defmodule Todo.Database do
  def store(key, data) do
    # replicates data across the cluster.
    # in a production-ready system we should handle cases of partial success
    # otherwise we end up with an inconsistent cluster.
    # possible solutions: 2-phase-commit + log-based database implementation
    {_results, bad_nodes} =
      :rpc.multicall(
        __MODULE__,
        :store_local,
        [key, data],
        :timer.seconds(5)
      )

    bad_nodes
    |> Enum.each(&IO.puts("Store failed on node #{&1}"))

    :ok
  end

  def store_local(key, data) do
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
    db_settings = Application.fetch_env!(:todo, :database)
    [name_prefix, _] = "#{node()}" |> String.split("@")
    db_folder = "#{Keyword.fetch!(db_settings, :folder)}/#{name_prefix}/"

    File.mkdir_p!(db_folder)

    :poolboy.child_spec(
      # child id
      __MODULE__,
      # pool options
      [
        # pool manager locally registered
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: Keyword.fetch!(db_settings, :pool_size)
      ],
      # worker arguments passed to start_link
      folder: db_folder
    )
  end
end
