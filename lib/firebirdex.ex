defmodule Firebirdex do
  alias Firebirdex.Query

  @type conn :: DBConnection.conn()

  @spec start_link(keyword()) :: {:ok, pid()} | {:error, Firebirdex.Error.t()}
  def start_link(opts) do
    DBConnection.start_link(Firebirdex.Protocol, opts)
  end

  @spec query(conn, iodata, list, keyword()) ::
          {:ok, Firebirdex.Result.t()} | {:error, Firebirdex.Error.t()}
  def query(conn, statement, params \\ [], opts \\ []) do
    query = %Query{name: "", statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} ->
        {:ok, result}
      {:error, _} = error ->
        error
    end

  end

  @spec query!(conn, iodata, list, keyword()) :: Firebirdex.Result.t()
  def query!(conn, statement, params \\ [], opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  @spec prepare(conn(), iodata(), iodata(), keyword()) ::
          {:ok, Firebirdex.Query.t()} | {:error, Firebirdex.Error.t()}
  def prepare(conn, name, statement, opts \\ []) do
    query = %Firebirdex.Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare(conn, query, opts)
  end

  @spec prepare!(conn(), iodata(), iodata(), keyword()) :: Firebirdex.Query.t()
  def prepare!(conn, name, statement, opts \\ []) do
    query = %Firebirdex.Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare!(conn, query, opts)
  end

  @spec prepare_execute(conn, iodata, iodata, list, keyword()) ::
          {:ok, Firebirdex.Query.t(), Firebirdex.Result.t()} | {:error, Firebirdex.Error.t()}
  def prepare_execute(conn, name, statement, params \\ [], opts \\ [])
      when is_binary(statement) or is_list(statement) do
    query = %Firebirdex.Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare_execute(conn, query, params, opts)
  end

  @spec prepare_execute!(conn, iodata, iodata, list, keyword()) ::
          {Firebirdex.Query.t(), Firebirdex.Result.t()}
  def prepare_execute!(conn, name, statement, params \\ [], opts \\ [])
      when is_binary(statement) or is_list(statement) do
    query = %Firebirdex.Query{name: name, statement: statement, ref: make_ref()}
    DBConnection.prepare_execute!(conn, query, params, opts)
  end

  @spec execute(conn(), Firebirdex.Query.t(), list(), keyword()) ::
          {:ok, Firebirdex.Query.t(), Firebirdex.Result.t()} | {:error, Firebirdex.Error.t()}
  defdelegate execute(conn, query, params \\ [], opts \\ []), to: DBConnection

  @spec execute!(conn(), Firebirdex.Query.t(), list(), keyword()) :: Firebirdex.Result.t()
  defdelegate execute!(conn, query, params \\ [], opts \\ []), to: DBConnection

  @spec close(conn(), Firebirdex.Query.t(), keyword()) :: :ok
  def close(conn, %Firebirdex.Query{} = query, opts \\ []) do
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
    DBConnection.child_spec(Firebirdex.Protocol, opts)
  end

end
