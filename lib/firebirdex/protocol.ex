defmodule Firebirdex.Protocol do
  @moduledoc false
  use DBConnection

  alias Firebirdex.{Query, Result}

  defstruct [
    :conn,
    transaction_status: :idle
  ]

  @impl true
  def connect(opts) do
    hostname = to_charlist(opts[:hostname])
    username = to_charlist(opts[:username])
    password = to_charlist(opts[:password])
    database = to_charlist(opts[:database])
    case :efirebirdsql_protocol.connect(hostname, username, password, database, opts) do
      {:ok, conn} ->
        {:ok, conn} = :efirebirdsql_protocol.begin_transaction(false, conn)
        {:ok, %__MODULE__{conn: conn}}
      {:error, message, _conn} ->
        {:error, %Firebirdex.Error{message: message}}
    end
  end

  @impl true
  def disconnect(_reason, state) do
    :efirebirdsql_protocol.close(state.conn)
    :ok
  end

  @impl true
  def ping(state) do
    # TODO
    {:ok, state}
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def checkin(state) do
    {:ok, state}
  end

  @impl true
  def handle_prepare(%Query{} = query, _opts, state) do
    {:ok, conn, stmt} = :efirebirdsql_protocol.allocate_statement(state.conn)
    {:ok, conn, stmt} = :efirebirdsql_protocol.prepare_statement(
      query.statement, conn, stmt)
    {:ok, %Query{query | stmt: stmt}, %__MODULE__{state | conn: conn}}
  end

  defp convert_param(param) do
    param
  end

  defp column_name({name, _type, _scale, _length, _isnull}) do
    name
  end

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    params = Enum.map(params, &convert_param(&1))
    {:ok, conn, stmt} = :efirebirdsql_protocol.execute(state.conn, query.stmt, params)
    {:ok, rows, conn, stmt} = :efirebirdsql_protocol.fetchall(conn, stmt)
    columns = Enum.map(:efirebirdsql_protocol.columns(stmt), &(column_name(&1)))
    {:ok, %Query{query | stmt: stmt}, %Result{rows: rows, columns: columns}, %__MODULE__{state | conn: conn}}
  end

  @impl true
  def handle_close(_query, _opts, state) do
    {:ok, conn} = :efirebirdsql_protocol.close(state.conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_status(_opts, status) do
    {status.transaction_status, status}
  end

  @impl true
  def handle_declare(query, _params, _opt, state) do
    {:ok, query, query.stmt, state}
  end

  @impl true
  def handle_begin(_opts, %{transaction_status: _status} = state) do
    {:ok, conn} = :efirebirdsql_protocol.begin_transaction(false, state.conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_commit(_opts, state) do
    {:ok, conn} = :efirebirdsql_protocol.commit(state.conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_rollback(_opts, state) do
    {:ok, conn} = :efirebirdsql_protocol.rollback(state.conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_fetch(_query, %Result{} = result, _opts, s) do
    {:halt, result, s}
  end

  @impl true
  def handle_deallocate(query, _cursor, _opts, state) do
    {:ok, conn} = :efirebirdsql_protocol.free_statement(state.conn, query.stmt, :drop)
    {:ok, %__MODULE__{state | conn: conn}}
  end

end
