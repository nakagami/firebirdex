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

    defp convert_value({_, :int64, _, _, _}, {_name, v}) do
      Decimal.new(to_string(v))
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
      %Result{result | rows: Enum.map(result.rows, &(convert_row([], columns, &1)))}
    end
  end

  defimpl String.Chars do
    def to_string(%{statement: statement}) do
      IO.iodata_to_binary(statement)
    end
  end
end
