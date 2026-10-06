defmodule ThreatShield.Scope do
  @moduledoc """
  Defined a scope for domain objects
  """
  alias ThreatShield.Accounts.User
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Systems.System

  defstruct [
    :id,
    :user,
    :organisation,
    :membership,
    :system,
    :asset,
    :threat
  ]

  @doc """
  Defined a scope for an organisation and optionally a threat for this organisation.
  """
  def for(%User{} = user, %Organisation{} = org) do
    id = to_string(org.id)

    %__MODULE__{
      id: id,
      user: user,
      organisation: org,
      membership: Organisation.get_membership(org, user)
    }
  end

  def for(%User{} = user, %Organisation{} = org, context) when is_list(context) do
    id = to_string(org.id)

    %__MODULE__{
      id: id,
      user: user,
      organisation: org,
      membership: Organisation.get_membership(org, user),
      threat: context[:threat],
      system: context[:system],
      asset: context[:asset]
    }
  end

  @doc """
  Defined a scope for a system and optionally a threat for this system.
  """
  def for_system(
        %User{} = user,
        %Organisation{} = org,
        %System{} = system
      ) do
    id = to_string(org.id) <> "-" <> to_string(system.id)

    %__MODULE__{
      id: id,
      user: user,
      organisation: org,
      membership: Organisation.get_membership(org, user),
      system: system
    }
  end
end
