defmodule Firebirdex.Encoding do
  def from_string!(s, :utf_8), do: s
  def from_string!(s, :cp932), do: Codepagex.from_string!(s, "VENDORS/MICSFT/WINDOWS/CP932")

  def to_string!(b, :utf_8), do: b
  def to_string!(b, :cp932), do: Codepagex.from_string!(b, "VENDORS/MICSFT/WINDOWS/CP932")

end
