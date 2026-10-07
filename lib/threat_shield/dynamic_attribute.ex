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

  @max_value_length 500

  @doc """
  Validates the attribute map of a changeset: every value must be a string of at
  most #{@max_value_length} characters.
  """
  def validate_values(%Ecto.Changeset{} = changeset, field) do
    Ecto.Changeset.validate_change(changeset, field, fn _field, attributes ->
      if is_map(attributes) and Enum.all?(attributes, &valid_value?/1) do
        []
      else
        [{field, "must be texts of at most #{@max_value_length} characters"}]
      end
    end)
  end

  defp valid_value?({_key, value}) when is_binary(value),
    do: String.length(value) <= @max_value_length

  defp valid_value?(_), do: false

  def init(nil) do
    :ets.new(@table, [:set, :public, :named_table])
    {:ok, nil}
  end
end
