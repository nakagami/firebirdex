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
      timezone: ~c"Asia/Tokyo"
    ]
  end

  def get_firebird_major_version(conn) do
    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT rdb$get_context('SYSTEM', 'ENGINE_VERSION') from rdb$database", [])
    {firebird_major_version, _} =  Integer.parse(hd hd result.rows)
    firebird_major_version
  end

end
