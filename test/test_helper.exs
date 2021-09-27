ExUnit.start()

defmodule TestHelpers do
  def opts() do 
    database = :lists.flatten(
      :io_lib.format("/tmp/~p.fdb", [:erlang.system_time()]))
    [
      hostname: "localhost",
      username: System.get_env("ISC_USER", "sysdba"),
      password: System.get_env("ISC_PASSWORD", "masterkey"),
      database: database,
      createdb: true,
      show_sensitive_data_on_connection_error: true,
      timezone: 'Asia/Tokyo'
    ]
  end
end
