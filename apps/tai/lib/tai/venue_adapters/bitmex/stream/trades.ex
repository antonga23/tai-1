defmodule Tai.VenueAdapters.Bitmex.Stream.Trades do
  def broadcast(
        %{
          "symbol" => venue_symbol,
          "timestamp" => timestamp,
          "price" => price,
          "size" => qty,
          "side" => side,
          "trdMatchID" => venue_trade_id
        },
        venue_id,
        received_at
      ) do
    Tai.Events.info(%Tai.Events.Trade{
      venue_id: venue_id,
      # TODO: 
      # The list of products or a map of exchange symbol to symbol should be 
      # passed in. This currently doesn't support _ within the symbol
      symbol: venue_symbol |> String.downcase() |> String.to_atom(),
      received_at: received_at,
      timestamp: timestamp,
      price: price,
      qty: qty,
      side: side |> normalize_side,
      venue_trade_id: venue_trade_id
    })
  end

  defp normalize_side("Buy"), do: :buy
  defp normalize_side("Sell"), do: :sell
end
