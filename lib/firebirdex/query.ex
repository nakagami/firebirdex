defmodule Firebirdex.Query do
  alias Firebirdex.Result

  @type t :: %__MODULE__{
          ref:  reference() | nil,
          name: iodata(),
          statement: iodata(),
          stmt: tuple()
        }

  defstruct name: "",
            ref: nil,
            stmt: nil,
            statement: nil,
            stmt: nil

  defimpl DBConnection.Query do
    def parse(query, _opts) do
      query
    end

    def describe(query, _opts) do
      query
    end

    def encode(%{stmt: nil} = query, _params, _opts) do
      raise ArgumentError, "query #{inspect(query)} has not been prepared"
    end

    def encode(_query, params, _opts) do
      params
    end

    defp convert_value({_, :long, scale, _, _}, {_name, v}) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :short, scale, _, _}, {_name, v}) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :int64, scale, _, _}, {_name, v}) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :quad, scale, _, _}, {_name, v}) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :date, _, _, _}, {_name, {YY, MM, DD}}) do
      Date.new(YY, MM, DD)
    end
    defp convert_value({_, :time, _, _, _}, {_name, {HH, MM, SS, MS}}) do
      Time.new(HH, MM, SS, MS)
    end
    defp convert_value({_, :timestamp, _, _, _}, {_name, {{YY, MM, DD}, {HH, MM, SS, MS}}}) do
      NaiveDateTime.new(YY, MM, DD, HH, MM, SS, MS)
    end
    defp convert_value({_, :time_tz, _, _, _}, {_name, {{HH, MM, SS, MS}, _TZ}}) do
      # TODO: timezone support
      Time.new(HH, MM, SS, MS)
    end
    defp convert_value({_, :timestamp_tz, _, _, _}, {_name, {{YY, MM, DD}, {HH, MM, SS, MS}, TZ}}) do
      DateTime.from_naive(NaiveDateTime.new(YY, MM, DD, HH, MM, SS, MS), TZ)
    end
    defp convert_value({_, _, _, _, _}, {_name, v}) do
      v
    end

    defp convert_row(row, [], []) do
      Enum.reverse(row)
    end
    defp convert_row(row, rest_columns, rest_row) do
      [c | rest_columns] = rest_columns
      [v | rest_row] = rest_row
      convert_row([convert_value(c, v) | row], rest_columns, rest_row)
    end

    def decode(query, result, _opts) do
      columns = :efirebirdsql_protocol.columns(query.stmt)
      rows = Enum.map(result.rows, &(convert_row([], columns, &1)))
      %Result{result | rows: rows, num_rows: length(rows)}
    end
  end

  defimpl String.Chars do
    def to_string(%{statement: statement}) do
      IO.iodata_to_binary(statement)
    end
  end
end
