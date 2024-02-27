defmodule Firebirdex.Query do
  alias Firebirdex.{Result, Encoding}

  @type t :: %__MODULE__{
          name: iodata(),
          statement: iodata(),
          stmt: tuple(),
          charset: atom()
        }

  defstruct name: nil,
            statement: nil,
            stmt: nil,
            charset: nil

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

    defp convert_value({_, _ , _, _, _}, {_name, nil}, _charset), do: nil
    defp convert_value({_, :long, scale, _, _}, {_name, v}, _charset) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :short, scale, _, _}, {_name, v}, _charset) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :int64, scale, _, _}, {_name, v}, _charset) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :quad, scale, _, _}, {_name, v}, _charset) when scale < 0 do
      Decimal.new(to_string(v))
    end
    defp convert_value({_, :date, _, _, _}, {_name, {year, month, day}}, _charset) do
      {:ok, v} = Date.new(year, month, day)
      v
    end
    defp convert_value({_, :time, _, _, _}, {_name, {hour, minute, second, microsecond}}, _charset) do
      {:ok, v} = Time.new(hour, minute, second, microsecond)
      v
    end
    defp convert_value({_, :timestamp, _, _, _}, {_name, {{year, month, day}, {hour, minute, second, microsecond}}}, _charset) do
      case NaiveDateTime.new(year, month, day, hour, minute, second, microsecond) do
          {:ok, datetime} -> datetime
          {:error, _} -> nil # Treat invalid timestamps as nil
        end
    end
    defp convert_value({_, :time_tz, _, _, _}, {_name, {{hour, minute, second, microsecond}, tz, offset}}, _charset) do
      d = Date.utc_today
      {:ok, dt} = NaiveDateTime.new(d.year, d.month, d.day, hour, minute, second)
      dttz1 = DateTime.from_naive!(dt, tz)
      {:ok, dttz2} = DateTime.shift_zone(dttz1, offset)
      {:ok, v} = Time.new(dttz2.hour, dttz2.minute, dttz2.second, microsecond)
      {v, offset}
    end
    defp convert_value({_, :timestamp_tz, _, _, _}, {_name, {{year, month, day}, {hour, minute, second, microsecond}, tz, offset}}, _charset) do
      {:ok, dt} = NaiveDateTime.new(year, month, day, hour, minute, second, microsecond)
      dttz = DateTime.from_naive!(dt, tz)
      {:ok, v} = DateTime.shift_zone(dttz, offset)
      v
    end
    defp convert_value({_, _, _, _, _}, {_name, v}, charset) when is_binary(v) do
      Encoding.to_string!(v, charset)
    end
    defp convert_value({_, _, _, _, _}, {_name, v}, _charset) do
      v
    end

    defp convert_row(row, [], [], _charset) do
      Enum.reverse(row)
    end
    defp convert_row(row, rest_columns, rest_row, charset) do
      [c | rest_columns] = rest_columns
      [v | rest_row] = rest_row
      convert_row([convert_value(c, v, charset) | row], rest_columns, rest_row, charset)
    end

    def decode(query, result, _opts) do
      rows = if result.rows == nil do
        result.rows
      else
        Enum.map(result.rows, &(convert_row([], result.desc, &1, query.charset)))
      end
      %Result{result | rows: rows, num_rows: result.num_rows}
    end
  end

  defimpl String.Chars do
    def to_string(%{statement: statement}) do
      IO.iodata_to_binary(statement)
    end
  end
end
