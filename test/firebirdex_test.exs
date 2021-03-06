defmodule FirebirdexTest do
  use ExUnit.Case, async: true

  @opts TestHelpers.opts()

  describe "basic_test" do
    opts = @opts
    {:ok, conn} = Firebirdex.start_link(opts)

    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT
        1 AS a,
        CAST('Str' AS VARCHAR(3)) AS b,
        1.23 AS c,
        CAST(1.23 AS DOUBLE PRECISION) AS d,
        NULL AS E
        FROM RDB$DATABASE", [])
    assert result.columns == ["A", "B", "C", "D", "E"]
    assert result.rows == [[1, "Str", Decimal.new("1.23"), 1.23, :nil]]

    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT
        CAST('1967-08-11' AS date) AS d,
        CAST('12:23:34.4567' AS time) AS t,
        CAST('1967-08-11 23:34:56.1234' AS timestamp) AS TS
        FROM RDB$DATABASE", [])
    assert result.columns == ["D", "T", "TS"]
    assert result.rows == [[~D[1967-08-11], ~T[12:23:34.456700], ~N[1967-08-11 23:34:56.123400]]]

    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT count(*) from rdb$relations where rdb$system_flag = ?", [0])
    assert result.rows == [[0]]

    {:error, %Firebirdex.Error{}} = Firebirdex.query(conn, "bad query", [])
    {:error, %Firebirdex.Error{}} = Firebirdex.query(conn,
      "SELECT * from rdb$relations where rdb$system_flag = ?", [<<"bad arg">>])

    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      ["SELECT 'a'", ?,, "'b' FROM RDB$DATABASE"], [])
    assert result.rows == [["a", "b"]]

    {:ok, _} = Firebirdex.query(conn,
      "CREATE TABLE foo (
          a INTEGER NOT NULL,
          b VARCHAR(30) NOT NULL UNIQUE,
          c VARCHAR(1024),
          d DECIMAL(16,3) DEFAULT -0.123,
          e DATE DEFAULT '1967-08-11',
          f TIMESTAMP DEFAULT '1967-08-11 23:45:01',
          g TIME DEFAULT '23:45:01',
          h BLOB SUB_TYPE 1,
          i DOUBLE PRECISION DEFAULT 0.0,
          j FLOAT DEFAULT 0.0,
          PRIMARY KEY (a),
          CONSTRAINT CHECK_A CHECK (a <> 0)
      )", [])
    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT * from foo", [])
    assert result.rows == []

  end
end
