defmodule Firebirdex.Connection do
  @moduledoc false
  use DBConnection

  alias Firebirdex.{Query, Result, Error, Encoding}
  require Record
  Record.defrecord :econn, Record.extract(:conn, from_lib: "efirebirdsql/include/efirebirdsql.hrl")

  defstruct [
    :conn,
    :transaction_status,
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
        {:ok, %__MODULE__{conn: conn, transaction_status: :idle}}
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
    case :efirebirdsql_protocol.ping(conn) do
      :ok -> {:ok, state}
      :error -> {:disconnect,__MODULE__,state}
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def handle_prepare(%Query{} = query, _opts, state) do
    charset = econn(state.conn, :charset)

    {:ok, stmt} = :efirebirdsql_protocol.unallocate_statement(to_string(query))
    {:ok, %Query{query | stmt: stmt, charset: charset}, %__MODULE__{state | conn: state.conn, transaction_status: :transaction}}
  end

  defp convert_param(%Decimal{} = value, _charset) do
    Decimal.to_string(value, :normal)
  end

  defp convert_param(%Date{} = d, _charset) do
    {d.year, d.month, d.day}
  end

  defp convert_param(%Time{} = t, _charset) do
    {t.hour, t.minute, t.second, 0}
  end

  defp convert_param(%NaiveDateTime{} = dt, _charset) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.minute, dt.second, 0}}
  end

  defp convert_param(%DateTime{} = dt, _charset) do
    {{dt.year, dt.month, dt.day}, {dt.hour, dt.minute, dt.second, 0}}
  end

  defp convert_param(param, charset) when is_binary(param) do
    Encoding.from_string!(param, charset)
  end

  defp convert_param(param, _charset) do
    param
  end

  defp column_name({name, _type, _scale, _length, _isnull}) do
    name
  end

  @impl true
  def handle_execute(%Query{} = query, params, _opts, state) do
    params = Enum.map(params, &convert_param(&1, econn(state.conn, :charset)))
    case :efirebirdsql_protocol.execute(state.conn, query.stmt, params) do
      {:ok, stmt} ->
        {:ok, rows, stmt} = :efirebirdsql_protocol.fetchall(state.conn, stmt)
        columns = Enum.map(:efirebirdsql_protocol.columns(stmt), &(column_name(&1)))
        {:ok, num_rows} = :efirebirdsql_protocol.rowcount(state.conn, stmt)
        {:ok, _conn} = :efirebirdsql_protocol.free_statement(state.conn, stmt, :drop)
        {:ok, %Query{query | stmt: stmt}, %Result{columns: columns, num_rows: num_rows, rows: rows}, %__MODULE__{state | conn: state.conn}}
      {:error, number, reason} ->
        {:error, %Error{number: number, reason: reason, statement: query.statement}, %__MODULE__{state | conn: state.conn}}
    end
  end

  @impl true
  def handle_close(_query, _opts, state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_declare(query, _params, _opt, state) do
    {:ok, query, query.stmt, state}
  end

  @impl true
  def handle_begin(opts, %{conn: conn, transaction_status: status} = s) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction when status == :idle ->
        case :efirebirdsql_protocol.begin_transaction(false, conn) do
          {:ok, conn} ->
            {:ok, %Result{}, %__MODULE__{conn: conn, transaction_status: :transaction}}
          {:error, _errno, _reason, _conn} ->
            {:error, s}
        end

      :savepoint when status == :transaction ->
        case :efirebirdsql_protocol.exec_immediate("SAVEPOINT firebirdex_savepoint", conn) do
          :ok ->
            {:ok, %Result{}, s}
          {:error, _errno, _reason, _conn} ->
            {:error, s}
        end

      mode when mode in [:transaction, :savepoint] ->
        {:ok, %Result{}, s}
    end

  end

  @impl true
  def handle_commit(opts, %{conn: conn, transaction_status: status} = s) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction when status == :transaction ->
        case :efirebirdsql_protocol.commit(conn) do
          :ok ->
            {:ok, %Result{}, %__MODULE__{conn: conn, transaction_status: :idle}}
          {:error, _errno, _reason} ->
            {:error, s}
        end

      :savepoint when status == :transaction ->
        case :efirebirdsql_protocol.exec_immediate("RELEASE SAVEPOINT firebirdex_savepoint", conn) do
          :ok ->
            {status, s}
          {:error, _errno, _reason, _conn} ->
            {:error, s}
        end

      mode when mode in [:transaction, :savepoint] ->
        {status, s}
    end

  end

  @impl true
  def handle_rollback(opts, %{conn: conn, transaction_status: status} = s) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction when status == :transaction ->
        case :efirebirdsql_protocol.rollback(conn) do
          :ok ->
            {:ok, %Result{}, %__MODULE__{conn: conn, transaction_status: :idle}}
          {:error, _errno, _reason} ->
            {:error, s}
        end

      :savepoint when status == :transaction ->
        case :efirebirdsql_protocol.exec_immediate("ROLLBACK TO SAVEPOINT firebirdex_savepoint", conn) do
          :ok ->
            {status, s}
          {:error, _errno, _reason, _conn} ->
            {:error, s}
        end

      mode when mode in [:transaction, :savepoint] ->
        {status, s}
    end

  end

  @impl true
  def handle_status(_opts, s) do
    {s.transaction_status, s}
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
