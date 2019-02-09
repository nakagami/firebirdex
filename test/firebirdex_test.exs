defmodule FirebirdexTest do
  use ExUnit.Case, async: true

  @opts TestHelpers.opts()

  describe "connect" do
    opts = @opts
    {:ok, conn} = Firebirdex.start_link(opts)
    {:ok, %Firebirdex.Result{}} = Firebirdex.query(conn, "SELECT 1 AS C FROM RDB$RELATIONS", [])
  end

end
