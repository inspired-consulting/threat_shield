defmodule ThreatShield.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  schema "assets" do
    field :is_candidate, :boolean, default: false
    field :description, :string

    belongs_to :system, System
    belongs_to :organisation, Organisation

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:description, :is_candidate, :system_id])
    |> validate_required([:description, :organisation])
  end

  def list_system_options(%Organisation{systems: systems}) do
    [{"None", nil} | Enum.map(systems, fn s -> {s.name, s.id} end)]
  end

  def system_name(%__MODULE__{system: %{name: name}}), do: name
  def system_name(_), do: "None"

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :asset, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [asset: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end
end
