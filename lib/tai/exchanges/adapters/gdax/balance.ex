defmodule Tai.Exchanges.Adapters.Gdax.Balance do
  alias Tai.Exchanges.Adapters.Gdax.Price
  alias Tai.Symbol

  def balance do
    ExGdax.list_accounts
    |> convert_to_usd
    |> Tai.Currency.sum
  end

  defp convert_to_usd({:ok, accounts}) do
    accounts
    |> Enum.map(&convert_account_to_usd/1)
  end

  defp convert_account_to_usd(%{"currency" => "USD", "balance" => balance}) do
    balance
    |> Decimal.new
  end
  defp convert_account_to_usd(%{"currency" => currency, "balance" => balance}) do
    balance
    |> Decimal.new
    |> Decimal.mult(usd_price(currency))
  end

  defp usd_price(currency) do
    "#{currency}usd"
    |> Symbol.downcase
    |> Price.price
    |> case do
      {:ok, price} -> price
    end
  end
end