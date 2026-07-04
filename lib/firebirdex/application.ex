defmodule Firebirdex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    case Calendar.get_time_zone_database() do
      Calendar.UTCOnlyTimeZoneDatabase ->
        Calendar.put_time_zone_database(Tz.TimeZoneDatabase)

      _ ->
        :ok
    end

    Supervisor.start_link([], strategy: :one_for_one, name: Firebirdex.Supervisor)
  end
end
