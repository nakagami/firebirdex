defmodule Firebirdex.Result do
  @type t :: %__MODULE__{
          desc: [] | nil,
          columns: [String.t()] | nil,
          num_rows: non_neg_integer() | nil,
          rows: [[term()]] | nil
        }

  defstruct [
    :desc,
    :columns,
    :num_rows,
    :rows
  ]
end
