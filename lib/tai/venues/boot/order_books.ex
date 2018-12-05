defmodule Tai.Venues.Boot.OrderBooks do
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  @spec start(adapter :: adapter, products :: [product]) :: :ok
  def start(adapter, products) do
    # TODO: This should have much better error handling
    Tai.Venues.OrderBookFeedsSupervisor.start_feed(adapter, products)
    :ok
  end
end
