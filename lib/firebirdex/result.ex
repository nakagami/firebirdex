defmodule Firebirdex.Result do
  @type t :: %__MODULE__{
          columns: [String.t()] | nil,
          num_rows: non_neg_integer() | nil,
          rows: [[term()]] | nil
        }

  defstruct [
    :columns,
    :num_rows,
    :rows
  ]
end
