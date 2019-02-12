defmodule Firebirdex.Query do
  require Record
  Record.defrecord :stmt, Record.extract(:stmt, from_lib: "efirebirdsql/include/efirebirdsql.hrl")

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

    defp convert_value({name, v}) do
      v
    end

    defp convert_row(row) do
      Enum.map(row, &(convert_value(&1)))
    end

    def decode(_query, result, _opts) do
      %Result{result | rows: Enum.map(result.rows, &(convert_row(&1)))}
    end
  end

  defimpl String.Chars do
    def to_string(%{statement: statement}) do
      IO.iodata_to_binary(statement)
    end
  end
end
