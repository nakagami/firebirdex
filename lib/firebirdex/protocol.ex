defmodule Firebirdex.Protocol do
  @moduledoc false
  use DBConnection

  require Logger

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
        {:ok, %__MODULE__{conn: conn}}
      {:error, number, reason, _conn} ->
        {:error, %Firebirdex.Error{number: number, reason: reason}}
    end
  end

  @impl true
  def disconnect(_reason, state) do
    Logger.debug "disconnect()"
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
    Logger.debug "handle_prepare() #{query}"
    {:ok, conn, stmt} = :efirebirdsql_protocol.allocate_statement(state.conn)
    case :efirebirdsql_protocol.prepare_statement(to_string(query), conn, stmt) do
      {:ok, conn, stmt} ->
        {:ok, %Query{query | stmt: stmt}, %__MODULE__{state | conn: conn}}
      {:error, number, reason, conn} ->
        {:error, %Firebirdex.Error{number: number, reason: reason, statement: query.statement}, %__MODULE__{state | conn: conn}}
    end
  end

  defp convert_param(param) do
    param
  end

  defp column_name({name, _type, _scale, _length, _isnull}) do
    name
  end

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    Logger.debug "handle_execute()"
    params = Enum.map(params, &convert_param(&1))
    case :efirebirdsql_protocol.execute(state.conn, query.stmt, params) do
      {:ok, conn, stmt} ->
      {:ok, rows, conn, stmt} = :efirebirdsql_protocol.fetchall(conn, stmt)
      columns = Enum.map(:efirebirdsql_protocol.columns(stmt), &(column_name(&1)))
      {:ok, %Query{query | stmt: stmt}, %Result{rows: rows, columns: columns}, %__MODULE__{state | conn: conn}}
    {:error, number, reason, conn} ->
      {:error, %Firebirdex.Error{number: number, reason: reason, statement: query.statement}, %__MODULE__{state | conn: conn}}
    end
  end

  @impl true
  def handle_close(_query, _opts, %{conn: conn, transaction_status: _status}) do
    Logger.debug "handle_close()"
    {:ok, conn} = :efirebirdsql_protocol.close(conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_status(_opts, %{conn: _conn, transaction_status: status}) do
    Logger.debug "handle_status() status=#{status}"
    {status.transaction_status, status}
  end

  @impl true
  def handle_declare(query, _params, _opt, state) do
    Logger.debug "handle_declare()"
    {:ok, query, query.stmt, state}
  end

  @impl true
  def handle_begin(opts, %{conn: conn, transaction_status: status} = s) do
    Logger.debug "handle_begin() status=#{status}"
    {:ok, conn} = :efirebirdsql_protocol.begin_transaction(false, conn)
    {s, %__MODULE__{conn: conn, transaction_status: :transaction}}

    #case Keyword.get(opts, :mode, :transaction) do
    #  :transaction when status == :idle ->
    #    {:ok, conn} = :efirebirdsql_protocol.begin_transaction(false, conn)
    #    {:ok, %Result{}, %__MODULE__{conn: conn, transaction_status: :transaction}}
    #  :savepoint when status == :transaction ->
    #    # TODO: savepoint
    #    {:ok, conn} = :efirebirdsql_protocol.begin_transaction(false, conn)
    #    {:ok, %Result{}, %__MODULE__{conn: conn, transaction_status: :transaction}}
    #  mode when mode in [:transaction, :savepoint] ->
    #    {status, s}
    #end

  end

  @impl true
  def handle_commit(_opts, %{conn: conn, transaction_status: status}) do
    Logger.debug "handle_commit() status=#{status}"
    {:ok, conn} = :efirebirdsql_protocol.commit(conn)
    {:transaction, %__MODULE__{conn: conn, transaction_status: :transaction}}
  end

  @impl true
  def handle_rollback(_opts, %{conn: conn, transaction_status: status}) do
    Logger.debug "handle_rollback() status=#{status}"
    {:ok, conn} = :efirebirdsql_protocol.rollback(conn)
    {:transaction, %__MODULE__{conn: conn, transaction_status: :transaction}}
  end

  @impl true
  def handle_fetch(_query, %Result{} = result, _opts, s) do
    Logger.debug "handle_fetch()"
    {:halt, result, s}
  end

  @impl true
  def handle_deallocate(query, _cursor, _opts, state) do
    Logger.debug "handle_deallocate()"
    {:ok, conn} = :efirebirdsql_protocol.free_statement(state.conn, query.stmt, :drop)
    {:ok, %__MODULE__{state | conn: conn}}
  end

end
