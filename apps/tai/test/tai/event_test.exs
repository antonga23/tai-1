defmodule Tai.EventTest do
  use ExUnit.Case, async: false

  describe ".encode!/1" do
    test "serializes events as json" do
      event =
        %{
          field_a: "Field A",
          field_b: "Field B"
        }
        |> Map.put(:__struct__, Tai.Events.MyEvent)

      assert Tai.Event.encode!(event) ==
               %{
                 type: "Tai.MyEvent",
                 data: %{
                   field_a: "Field A",
                   field_b: "Field B"
                 }
               }
               |> Jason.encode!()
    end

    test "uses the struct name for non-system events" do
      event = %{} |> Map.put(:__struct__, MyCustomEvent)

      assert Tai.Event.encode!(event) ==
               %{
                 type: "MyCustomEvent",
                 data: %{}
               }
               |> Jason.encode!()
    end

    test "can provide a custom data transformation" do
      event =
        %{hello: "world"}
        |> Map.put(:__struct__, Support.CustomEvent)

      assert Tai.Event.encode!(event) ==
               %{
                 type: "Support.CustomEvent",
                 data: %{
                   hello: "custom"
                 }
               }
               |> Jason.encode!()
    end

    test "it encodes Decimal values to string" do
      defmodule MyDecimalEvent do
        defstruct [:decimal]
      end

      event =
        %{decimal: Decimal.cast(42.0)}
        |> Map.put(:__struct__, MyDecimalEvent)

      assert Tai.Event.encode!(event) ==
               %{
                 type: "Tai.EventTest.MyDecimalEvent",
                 data: %{
                   decimal: "42.0"
                 }
               }
               |> Jason.encode!()
    end
  end
end
