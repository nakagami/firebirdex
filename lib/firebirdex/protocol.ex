defmodule Firebirdex.Protocol do
  @moduledoc false
  use DBConnection

  require Logger

  alias Firebirdex.{Query, Result}

  defstruct [
    :conn
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

  defp convert_param(%Decimal{} = value) do
    Decimal.to_string(value, :normal)
  end

  defp convert_param(%NaiveDateTime{} = dt) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.second, dt.second, 0}}
  end

  defp convert_param(%DateTime{} = dt) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.second, dt.second, 0}}
  end

  defp convert_param(param) do
    param
  end

  defp column_name({name, _type, _scale, _length, _isnull}) do
    name
  end

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    Logger.debug "handle_execute() #{inspect(params)}"
    params = Enum.map(params, &convert_param(&1))
    Logger.debug "handle_execute() #{inspet(params)}"
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
  def handle_close(_query, _opts, %{conn: conn}) do
    {:ok, conn} = :efirebirdsql_protocol.close(conn)
    {:ok, %__MODULE__{conn: conn}}
  end

  @impl true
  def handle_declare(query, _params, _opt, state) do
    {:ok, query, query.stmt, state}
  end

  @impl true
  def handle_begin(_opts, %{conn: conn}) do
    case :efirebirdsql_protocol.begin_transaction(false, conn) do
      {:ok, conn} ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason, conn} ->
        {:error, %__MODULE__{conn: conn}}
    end
  end

  @impl true
  def handle_commit(_opts, %{conn: conn}) do
    case :efirebirdsql_protocol.commit(conn) do
      {:ok, conn} ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason, conn} ->
        {:error, %__MODULE__{conn: conn}}
    end
  end

  @impl true
  def handle_rollback(_opts, %{conn: conn}) do
    case :efirebirdsql_protocol.rollback(conn) do
      {:ok, conn} ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason, conn} ->
        {:error, %__MODULE__{conn: conn}}
    end
  end

  @impl true
  def handle_status(_opts, s) do
    # TODO: transaction status treatment
    {:transaction, s}
  end

  @impl true
  def handle_fetch(_query, %Result{} = result, _opts, s) do
    {:halt, result, s}
  end

  @impl true
  def handle_deallocate(query, _cursor, _opts, state) do
    case :efirebirdsql_protocol.free_statement(state.conn, query.stmt, :drop) do
      {:ok, conn, _stmt} ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason, conn} ->
        {:error, %__MODULE__{conn: conn}}
    end
  end

end
