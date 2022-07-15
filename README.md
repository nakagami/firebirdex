# Firebirdex

Elixir database driver for Firebird https://firebirdsql.org/

## Requirements

Firebird 2.5 or higher

## Preparation

Add `:firebirdex` to your dependencies:

```elixir
def deps() do
  [
    {:firebirdex, "~> 0.2"}
  ]
end
```

## Example

```elixir
opts = [
  hostname: "servername",
  username: "sysdba",
  password: "password",
  database: "/some/where/sample.fdb",
]

{:ok, pid} = Firebirdex.start_link(opts)

{:ok, %Firebirdex.Result{} = result} = Firebirdex.query(pid, Firebirdex.query("SELECT * FROM rdb$relations where rdb$system_flag = ?", [1]))

IO.inspect result.columns
IO.inspect Enum.at result.rows, 0

# Same as above (may raise an exception)
result = Firebirdex.query!(pid, Firebirdex.query("SELECT * FROM rdb$relations where rdb$system_flag = ?", [1]))
```

