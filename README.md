# Firebirdex

Elixir database driver for Firebird https://firebirdsql.org/

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

```
opts = [
  hostname: "servername",
  username: "sysdba",
  password: "password",
  database: "/some/where/sample.fdb",
  show_sensitive_data_on_connection_error: true,
]

{:ok, pid} = Firebirdex.start_link(opts)
{:ok, %Firebirdex.Result{} = result} = Firebirdex.query(pid, Firebirdex.query("SELECT * FROM rdb$relations where rdb$system_flag = ?", [1]))

IO.inspect result.columns
IO.inspect result.rows[0]
```
