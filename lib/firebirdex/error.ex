defmodule Firebirdex.Error do
  defexception [
    :message,
    :statement
  ]

  @type t :: %__MODULE__{
          message: String.t(),
          statement: iodata() | nil
        }
end
