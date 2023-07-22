# Firebirdex

Elixir database driver for Firebird https://firebirdsql.org/

## Requirements

Firebird 2.5 or higher

## Preparation

Add `:firebirdex` to your dependencies:

```elixir
def deps() do
  [
    {:firebirdex, "~> 0.3.10"}
  ]
end
```

## Example

If the password is set in the FIREBIRD_PASSWORD environment variable, you can omit the password in the opts variable below.

```elixir
opts = [
  hostname: "servername",
  username: "sysdba",
  password: "password",
  database: "/some/where/sample.fdb",
]

{:ok, pid} = Firebirdex.start_link(opts)

{:ok, %Firebirdex.Result{} = result} = Firebirdex.query(pid, "SELECT * FROM rdb$relations where rdb$system_flag = ?", [1])

IO.inspect result.columns
IO.inspect Enum.at result.rows, 0

# Same as above (may raise an exception)
result = Firebirdex.query!(pid, "SELECT * FROM rdb$relations where rdb$system_flag = ?", [1])
```

