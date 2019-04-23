defmodule Tai.Venues.Adapters.CancelOrderErrorTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  setup_all do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{adapter.id} #{error_reason} error" do
        enqueued_order = build_enqueued_order(@adapter.id)

        use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_#{@error_reason}" do
          assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

          open_order = build_open_order(enqueued_order, order_response)

          with_mock HTTPoison,
            request: fn _url -> {:error, %HTTPoison.Error{reason: @error_reason}} end do
            assert {:error, reason} = Tai.Venue.cancel_order(open_order, @test_adapters)
            assert reason == @error_reason
          end
        end
      end
    end)

    test "#{adapter.id} overloaded error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_overloaded_error" do
        assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venue.cancel_order(open_order, @test_adapters) == {:error, :overloaded}
      end
    end

    test "#{adapter.id} nonce not increasing error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_nonce_not_increasing_error" do
        assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venue.cancel_order(open_order, @test_adapters)

        assert msg != nil
      end
    end

    test "#{adapter.id} rate limited error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_rate_limited_error" do
        assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venue.cancel_order(open_order, @test_adapters) == {:error, :rate_limited}
      end
    end

    test "#{adapter.id} unhandled error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_unhandled_error" do
        assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:unhandled, error}} = Tai.Venue.cancel_order(open_order, @test_adapters)

        assert error != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      exchange_id: venue_id,
      account_id: :main,
      symbol: venue_id |> product_symbol,
      side: :buy,
      price: venue_id |> price(),
      qty: venue_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, order_response) do
    struct(Tai.Trading.Order, %{
      venue_order_id: order_response.id,
      exchange_id: order.exchange_id,
      account_id: :main,
      symbol: order.exchange_id |> product_symbol,
      side: :buy,
      price: order.exchange_id |> price(),
      qty: order.exchange_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex), do: :eth_usd_190426
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex), do: Decimal.new("100.5")
  defp price(:okex), do: Decimal.new("100.5")

  defp qty(:bitmex), do: Decimal.new(1)
  defp qty(:okex), do: Decimal.new(1)
end