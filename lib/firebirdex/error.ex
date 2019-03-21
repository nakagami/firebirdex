defmodule Firebirdex.Error do
  defexception [:number, :reason, :statement]

  @type t :: %__MODULE__{
    number: integer(),
    reason: String.t(),
    statement: iodata() | nil
  }

  def message(e) do
    if e.statement == nil do
      "#{e.number}:#{e.reason}"
    else
      "#{e.number}:#{e.reason}\t#{IO.iodata_to_binary(e.statement)}"
    end
  end

end
