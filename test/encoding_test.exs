defmodule Firebirdex.EncodingTest do
  use ExUnit.Case, async: true

  @isc_malformed_string 335_544_849
  @sql "SELECT CAST(? AS VARCHAR(40)) FROM RDB$DATABASE"

  # Anything above U+00FF has no Latin-1 mapping: em dashes, curly quotes, ellipses, the euro
  # sign, emoji -- what comes out of pasting from a word processor or a PDF.
  @unencodable ["an — em dash", "a “quoted” word", "an ellipsis…", "costs 100 €", "an emoji 🙂"]

  test "a parameter the charset cannot represent is an error, not a raise" do
    {:ok, conn} = Firebirdex.start_link(latin1_opts())

    for param <- @unencodable do
      assert {:error, %Firebirdex.Error{} = error} = Firebirdex.query(conn, @sql, [param])
      assert error.number == @isc_malformed_string
      assert error.reason =~ "Malformed string"
    end
  end

  test "the error names the characters that could not be encoded" do
    {:ok, conn} = Firebirdex.start_link(latin1_opts())

    assert {:error, %Firebirdex.Error{} = error} = Firebirdex.query(conn, @sql, ["an — and a €"])

    assert error.reason =~ "—"
    assert error.reason =~ "€"
    # Only the offending ones: the rest of the string is representable and stays out of the way.
    refute error.reason =~ "and a"
  end

  test "the statement is carried on the error, like any other failed query" do
    {:ok, conn} = Firebirdex.start_link(latin1_opts())

    assert {:error, %Firebirdex.Error{} = error} = Firebirdex.query(conn, @sql, ["—"])
    assert IO.iodata_to_binary(error.statement) == @sql
  end

  test "the connection stays usable after the failure" do
    {:ok, conn} = Firebirdex.start_link(latin1_opts())

    assert {:error, %Firebirdex.Error{}} = Firebirdex.query(conn, @sql, ["—"])

    assert {:ok, %Firebirdex.Result{rows: [[1]]}} =
             Firebirdex.query(conn, "SELECT 1 FROM RDB$DATABASE", [])
  end

  test "everything the charset does cover still goes through untouched" do
    {:ok, conn} = Firebirdex.start_link(latin1_opts())

    # Latin-1 represents every codepoint up to U+00FF in a single byte, accents included.
    assert {:ok, %Firebirdex.Result{rows: [[value]]}} =
             Firebirdex.query(conn, @sql, ["café crème ÀÉÎÕÜ"])

    assert value == "café crème ÀÉÎÕÜ"
  end

  test "a utf_8 connection encodes what Latin-1 cannot" do
    {:ok, conn} = Firebirdex.start_link(Keyword.put(TestHelpers.opts(), :charset, :utf_8))

    assert {:ok, %Firebirdex.Result{rows: [["an — em dash"]]}} =
             Firebirdex.query(conn, @sql, ["an — em dash"])
  end

  # Called per test, not stored in a module attribute: each connection gets its own database
  # name, so the async tests do not race on "object DATABASE is in use".
  defp latin1_opts, do: Keyword.put(TestHelpers.opts(), :charset, :iso8859_1)
end
