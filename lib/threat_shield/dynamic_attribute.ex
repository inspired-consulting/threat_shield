defmodule ThreatShield.DynamicAttribute do
  use GenServer

  @table :attribute_suggestions

  alias ThreatShield.AI

  @enforce_keys [:name, :description]
  defstruct [:name, :description, :sample_values]

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_suggestions(%__MODULE__{sample_values: nil} = attribute) do
    :ets.lookup_element(@table, attribute, 2)
  rescue
    _ ->
      suggestions = AI.suggest_values(attribute)
      :ets.insert(@table, {attribute, suggestions})
      suggestions
  end

  def get_suggestions(%__MODULE__{sample_values: handcoded_values}), do: handcoded_values

  def init(nil) do
    :ets.new(@table, [:set, :public, :named_table])
    {:ok, nil}
  end
end
