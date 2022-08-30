defmodule Firebirdex.Connection do
  @moduledoc false
  use DBConnection

  alias Firebirdex.{Query, Result, Error}

  defstruct [
    :conn
  ]

  @impl true
  def connect(opts) do
    hostname = to_charlist(opts[:hostname])
    username = to_charlist(opts[:username])
    password = Keyword.get(opts, :password, System.get_env("FIREBIRD_PASSWORD"))
    password = to_charlist(password)
    database = to_charlist(opts[:database])
    case :efirebirdsql_protocol.connect(hostname, username, password, database, opts) do
      {:ok, conn} ->
        {:ok, %__MODULE__{conn: conn}}
      {:error, number, reason, _conn} ->
        {:error, %Error{number: number, reason: reason}}
    end
  end

  @impl true
  def disconnect(_reason,  %__MODULE__{conn: conn}) do
    case :efirebirdsql_protocol.close(conn) do
      {:ok, _conn} ->
        :ok
      {:error, number, reason, _conn} ->
        {:error, %Error{number: number, reason: reason}}
    end
  end

  @impl true
  def ping( %__MODULE__{conn: conn} = state) do
    sql = "SELECT rdb$get_context('SYSTEM', 'ENGINE_VERSION') from rdb$database"
    with {:ok,statement} <- :efirebirdsql_protocol.allocate_statement(conn),
      {:ok,statement} <- :efirebirdsql_protocol.prepare_statement(sql, conn, statement),
      {:ok,_} <- :efirebirdsql_protocol.execute(conn, statement),
      {:ok,_} <- :efirebirdsql_protocol.free_statement(conn,statement,:close)
    do
      {:ok,state}
      # Uncomment following line for testing purposes. It will disonnect/reconnect randomly
      # if :rand.uniform(5) == 2, do: {:disconnect,__MODULE__,state}, else: {:ok,state}
    else
      _ -> {:disconnect,__MODULE__,state}
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def handle_prepare(%Query{} = query, _opts, state) do
    {:ok, stmt} = :efirebirdsql_protocol.allocate_statement(state.conn)
    case :efirebirdsql_protocol.prepare_statement(to_string(query), state.conn, stmt) do
      {:ok, stmt} ->
        {:ok, %Query{query | stmt: stmt}, %__MODULE__{state | conn: state.conn}}
      {:error, number, reason} ->
        {:error, %Error{number: number, reason: reason, statement: query.statement}, %__MODULE__{state | conn: state.conn}}
    end
  end

  defp convert_param(%Decimal{} = value) do
    Decimal.to_string(value, :normal)
  end

  defp convert_param(%Date{} = d) do
    {d.year, d.month, d.day}
  end

  defp convert_param(%Time{} = t) do
    {t.hour, t.minute, t.second, 0}
  end

  defp convert_param(%NaiveDateTime{} = dt) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.minute, dt.second, 0}}
  end

  defp convert_param(%DateTime{} = dt) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.minute, dt.second, 0}}
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
    case :efirebirdsql_protocol.execute(state.conn, query.stmt, params) do
      {:ok, stmt} ->
        {:ok, rows, stmt} = :efirebirdsql_protocol.fetchall(state.conn, stmt)
        columns = Enum.map(:efirebirdsql_protocol.columns(stmt), &(column_name(&1)))
        {:ok, num_rows} = :efirebirdsql_protocol.rowcount(state.conn, stmt)
        {:ok, %Query{query | stmt: stmt}, %Result{columns: columns, num_rows: num_rows, rows: rows}, %__MODULE__{state | conn: state.conn}}
      {:error, number, reason} ->
        {:error, %Error{number: number, reason: reason, statement: query.statement}, %__MODULE__{state | conn: state.conn}}
    end
  end

  @impl true
  def handle_close(_query, _opts, state) do
    with {:ok, conn} <- :efirebirdsql_protocol.close(state.conn) do
      {:ok, nil, %__MODULE__{state | conn: conn}}
    end
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
      :ok ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason} ->
        {:error, %__MODULE__{conn: conn}}
    end
  end

  @impl true
  def handle_rollback(_opts, %{conn: conn}) do
    case :efirebirdsql_protocol.rollback(conn) do
      :ok ->
        {:ok, %Result{}, %__MODULE__{conn: conn}}
      {:error, _errno, _reason} ->
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
      {:ok, _stmt} ->
        {:ok, %Result{}, %__MODULE__{conn: state.conn}}
      {:error, _errno, _reason} ->
        {:error, %__MODULE__{conn: state.conn}}
    end
  end

end
