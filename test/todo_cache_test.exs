defmodule TodoCacheTest do
  use ExUnit.Case
  alias Todo.{Cache, Server}

  test "server_process" do
    bob_pid = Cache.server_process("bob")

    assert bob_pid != Cache.server_process("alice")
    assert bob_pid == Cache.server_process("bob")
  end

  # test "to-do operations" do
  #   # cheating
  #   name = "alice #{to_string(DateTime.utc_now())}"
  #   alice = Cache.server_process(name)
  #   Server.add_entry(alice, %{date: ~D[2019-06-27], title: "Dentist"})

  #   assert [%{date: ~D[2019-06-27], title: "Dentist"}] = Server.entries(alice)
  # end

end
