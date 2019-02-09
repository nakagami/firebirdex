ExUnit.start()

defmodule TestHelpers do
  def opts() do 
    database = :lists.flatten(
      :io_lib.format("/tmp/~p.fdb", [:erlang.system_time()]))
    [
      hostname: "localhost",
      username: "sysdba",
      password: "masterkey",
      database: database,
      createdb: true,
      show_sensitive_data_on_connection_error: true
    ]
  end
end
