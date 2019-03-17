defmodule Firebirdex.Error do
  defexception [
    :number,
    :message,
    :statement
  ]

  @type t :: %__MODULE__{
          number: integer(),
          message: String.t(),
          statement: iodata() | nil
        }
end
