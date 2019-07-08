defmodule Todo.DatabaseWorker do
  use GenServer

  # API
  def start_link(folder: folder) do
    IO.puts("Starting database worker")
    GenServer.start_link(__MODULE__, folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  # Server

  @impl GenServer
  def init(folder) do
    {:ok, folder}
  end


  @impl GenServer
  def handle_cast({:store, key, data}, folder) do
    # database worker per request
    key
    |> file_name(folder)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, folder}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, folder) do
    data =
      case File.read(file_name(key, folder)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, folder}
  end

  defp file_name(key, folder) do
    Path.join(folder, to_string(key))
  end
end
