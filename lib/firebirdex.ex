defmodule Firebirdex do
  alias Firebirdex.Connection
  alias Firebirdex.Error
  alias Firebirdex.Query
  alias Firebirdex.Result

  @type conn :: DBConnection.conn()

  @spec start_link(keyword()) :: {:ok, pid()} | {:error, Error.t()}
  def start_link(opts) do
    DBConnection.start_link(Connection, opts)
  end

  @spec query(conn, iodata, list, keyword()) ::
          {:ok, Result.t()} | {:error, Error.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} ->
        {:ok, result}
      {:error, _} = error ->
        error
    end

  end

  @spec query!(conn, iodata, list, keyword()) :: Result.t()
  def query!(conn, statement, params \\ [], opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  @spec prepare(conn(), iodata(), iodata(), keyword()) ::
          {:ok, Query.t()} | {:error, Error.t()}
  def prepare(conn, name, statement, opts \\ []) do
    query = %Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare(conn, query, opts)
  end

  @spec prepare!(conn(), iodata(), iodata(), keyword()) :: Query.t()
  def prepare!(conn, name, statement, opts \\ []) do
    query = %Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare!(conn, query, opts)
  end

  @spec prepare_execute(conn, iodata, iodata, list, keyword()) ::
          {:ok, Query.t(), Result.t()} | {:error, Error.t()}
  def prepare_execute(conn, name, statement, params \\ [], opts \\ [])
      when is_binary(statement) or is_list(statement) do
    query = %Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare_execute(conn, query, params, opts)
  end

  @spec prepare_execute!(conn, iodata, iodata, list, keyword()) ::
          {Query.t(), Result.t()}
  def prepare_execute!(conn, name, statement, params \\ [], opts \\ [])
      when is_binary(statement) or is_list(statement) do
    query = %Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare_execute!(conn, query, params, opts)
  end

  @spec execute(conn(), Query.t(), list(), keyword()) ::
          {:ok, Query.t(), Result.t()} | {:error, Error.t()}
  defdelegate execute(conn, query, params \\ [], opts \\ []), to: DBConnection

  @spec execute!(conn(), Query.t(), list(), keyword()) :: Result.t()
  defdelegate execute!(conn, query, params \\ [], opts \\ []), to: DBConnection

  @spec close(conn(), Query.t(), keyword()) :: :ok
  def close(conn, %Query{} = query, opts \\ []) do
    case DBConnection.close(conn, query, opts) do
      {:ok, _} ->
        :ok

      {:error, _} = error ->
        error
    end
  end

  @spec transaction(conn, (DBConnection.t() -> result), keyword()) ::
          {:ok, result} | {:error, any}
        when result: var
  defdelegate transaction(conn, fun, opts \\ []), to: DBConnection

  @spec rollback(DBConnection.t(), any()) :: no_return()
  defdelegate rollback(conn, reason), to: DBConnection

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    DBConnection.child_spec(Connection, opts)
  end

end
