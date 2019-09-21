defmodule Tai.VenueAdapters.Binance.StreamSupervisor do
  use Supervisor
  alias Tai.VenueAdapters.Binance.Stream.OrderBookStore

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type channel :: Tai.Venues.Adapter.channel()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(
          venue_id: venue_id,
          channels: [channel],
          accounts: map,
          products: [product],
          opts: map
        ) ::
          Supervisor.on_start()
  def start_link([venue_id: venue_id, channels: _, accounts: _, products: _, opts: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: :"#{__MODULE__}_#{venue_id}")
  end

  # TODO: Make this configurable
  @base_url "wss://stream.binance.com:9443/stream"

  def init(venue_id: venue_id, channels: _, accounts: accounts, products: products, opts: _) do
    # TODO: Potentially this could use new order books? Send the change quote
    # event to subscribing advisors?
    order_books =
      products
      |> Enum.map(fn p ->
        name = Tai.Markets.OrderBook.to_name(venue_id, p.symbol)

        %{
          id: name,
          start: {
            Tai.Markets.OrderBook,
            :start_link,
            [[feed_id: venue_id, symbol: p.symbol]]
          }
        }
      end)

    order_book_stores =
      products
      |> Enum.map(fn p ->
        %{
          id: OrderBookStore.to_name(venue_id, p.venue_symbol),
          start: {OrderBookStore, :start_link, [p]}
        }
      end)

    system = [
      {Tai.VenueAdapters.Binance.Stream.ProcessOrderBooks,
       [venue_id: venue_id, products: products]},
      {Tai.VenueAdapters.Binance.Stream.ProcessMessages, [venue_id: venue_id]},
      {Tai.VenueAdapters.Binance.Stream.Connection,
       [
         url: products |> url(),
         venue_id: venue_id,
         account: accounts |> Map.to_list() |> List.first(),
         products: products
       ]}
    ]

    (order_books ++ order_book_stores ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp url(products) do
    streams =
      products
      |> Enum.map(& &1.venue_symbol)
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&"#{&1}@depth")
      |> Enum.join("/")

    "#{@base_url}?streams=#{streams}"
  end
end
