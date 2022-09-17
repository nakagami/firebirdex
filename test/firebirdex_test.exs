defmodule FirebirdexTest do
  use ExUnit.Case, async: true

  @opts TestHelpers.opts()

  test "connect_test" do
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
    result = Firebirdex.query!(conn, "SELECT * from foo", [])
    assert result.rows == []

    {:ok, _} = Firebirdex.query(conn,
      "INSERT INTO foo (a, b, c, d) VALUES (1, 'A', NULL, NULL)", [])
    {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn,
      "SELECT c, d FROM foo", [])
      assert result.rows == [
        [nil, nil]
      ]

    firebird_major_version = TestHelpers.get_firebird_major_version(conn)
    if firebird_major_version > 3 do
      # timezone test
      {:ok, _} = Firebirdex.query(conn,
        "CREATE TABLE tz_test (
            id INTEGER NOT NULL,
            t TIME WITH TIME ZONE DEFAULT '12:34:56',
            ts TIMESTAMP WITH TIME ZONE DEFAULT '1967-08-11 23:45:01',
            PRIMARY KEY (id)
        )", [])
      {:ok, _} = Firebirdex.query(conn, "insert into tz_test (id) values (1)", [])
      {:ok, _} = Firebirdex.query(conn, "insert into tz_test (id, t, ts) values (2, '12:34:56 Asia/Seoul', '1967-08-11 23:45:01.0000 Asia/Seoul')", [])
      {:ok, _} = Firebirdex.query(conn, "insert into tz_test (id, t, ts) values (3, '03:34:56 UTC', '1967-08-11 14:45:01.0000 UTC')", [])

      {:ok, %Firebirdex.Result{} = result} = Firebirdex.query(conn, "SELECT * from tz_test", [])

      assert result.columns == ["ID", "T", "TS"]
      assert result.rows == [
        [1, {~T[12:34:56.000000], "Asia/Tokyo"}, DateTime.from_naive!(~N[1967-08-11 23:45:01.000000], "Asia/Tokyo")],
        [2, {~T[12:34:56.000000], "Asia/Seoul"}, DateTime.from_naive!(~N[1967-08-11 23:45:01.000000], "Asia/Seoul")],
        [3, {~T[03:34:56.000000], "UTC"}, DateTime.from_naive!(~N[1967-08-11 14:45:01.000000], "UTC")]
      ]
    end

  end

  test "encoding_test" do
    assert Firebirdex.Encoding.from_string!("", :utf_8) == ""
    assert Firebirdex.Encoding.from_string!("", :cp932) == ""
    assert Firebirdex.Encoding.from_string!("", :cp437) == ""
    assert Firebirdex.Encoding.from_string!("", :cp850) == ""
    assert Firebirdex.Encoding.from_string!("", :cp865) == ""
    assert Firebirdex.Encoding.from_string!("", :cp860) == ""
    assert Firebirdex.Encoding.from_string!("", :cp863) == ""
    assert Firebirdex.Encoding.from_string!("", :cp775) == ""
    assert Firebirdex.Encoding.from_string!("", :cp862) == ""
    assert Firebirdex.Encoding.from_string!("", :cp864) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_1) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_2) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_3) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_4) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_5) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_6) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_7) == ""
    assert Firebridex.Encoding.from_string!("", :iso8859_8) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_9) == ""
    assert Firebirdex.Encoding.from_string!("", :iso8859_13) == ""
    assert Firebirdex.Encoding.from_string!("", :cp852) == ""
    assert Firebirdex.Encoding.from_string!("", :cp857) == ""
    assert Firebirdex.Encoding.from_string!("", :cp861) == ""
    assert Firebirdex.Encoding.from_string!("", :cp866) == ""
    assert Firebirdex.Encoding.from_string!("", :cp869) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1250) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1251) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1252) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1253) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1254) == ""
    assert Firebirdex.Encoding.from_string!("", :cp950) == ""
    assert Firebirdex.Encoding.from_string!("", :cp936) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1255) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1256) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1257) == ""
    assert Firebirdex.Encoding.from_string!("", :koi8_r) == ""
    assert Firebirdex.Encoding.from_string!("", :koi8_u) == ""
    assert Firebirdex.Encoding.from_string!("", :cp1258) == ""
  end

  test "decoding_test" do
    assert Firebirdex.Encoding.to_string!("", :utf_8) == ""
    assert Firebirdex.Encoding.to_string!("", :cp932) == ""
    assert Firebirdex.Encoding.to_string!("", :cp437) == ""
    assert Firebirdex.Encoding.to_string!("", :cp850) == ""
    assert Firebirdex.Encoding.to_string!("", :cp865) == ""
    assert Firebirdex.Encoding.to_string!("", :cp860) == ""
    assert Firebirdex.Encoding.to_string!("", :cp863) == ""
    assert Firebirdex.Encoding.to_string!("", :cp775) == ""
    assert Firebirdex.Encoding.to_string!("", :cp862) == ""
    assert Firebirdex.Encoding.to_string!("", :cp864) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_1) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_2) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_3) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_4) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_5) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_6) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_7) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_8) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_9) == ""
    assert Firebirdex.Encoding.to_string!("", :iso8859_13) == ""
    assert Firebirdex.Encoding.to_string!("", :cp852) == ""
    assert Firebirdex.Encoding.to_string!("", :cp857) == ""
    assert Firebirdex.Encoding.to_string!("", :cp861) == ""
    assert Firebirdex.Encoding.to_string!("", :cp866) == ""
    assert Firebirdex.Encoding.to_string!("", :cp869) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1250) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1251) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1252) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1253) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1254) == ""
    assert Firebirdex.Encoding.to_string!("", :cp950) == ""
    assert Firebirdex.Encoding.to_string!("", :cp936) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1255) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1256) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1257) == ""
    assert Firebirdex.Encoding.to_string!("", :koi8_r) == ""
    assert Firebirdex.Encoding.to_string!("", :koi8_u) == ""
    assert Firebirdex.Encoding.to_string!("", :cp1258) == ""
  end

end
