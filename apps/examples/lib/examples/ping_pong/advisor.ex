defmodule Examples.PingPong.Advisor do
  @moduledoc """
  Place a passive limit order inside the current quote and immediately flip it
  on the opposing quote side upon fill.

  PLEASE NOTE:
  This advisor is for demonstration purposes only. It does not take into account
  all scenarios required in a production environment. Do not trade this advisor with
  real funds.
  """

  use Tai.Advisor
  import Examples.PingPong.ManageQuoteChange, only: [with_all_quotes: 1, manage_entry_order: 2]
  import Examples.PingPong.ManageOrderUpdate, only: [entry_order_updated: 2]

  def handle_inside_quote(_, _, market_quote, _, state) do
    market_quote
    |> with_all_quotes()
    |> manage_entry_order(state)
  end

  def handle_info({:order_updated, _prev, updated, :entry_order}, state) do
    {:ok, new_run_store} =
      state.store
      |> update_store_order(:entry_order, updated)
      |> entry_order_updated(state)

    new_state = Map.put(state, :store, new_run_store)

    {:noreply, new_state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp update_store_order(run_store, name, order), do: run_store |> Map.put(name, order)
end