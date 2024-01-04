defmodule ThreatShield.Scope do
  @moduledoc """
  Defined a scope for domain objects
  """
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System

  defstruct [
    :id,
    :user,
    :organisation,
    :membership,
    :system,
    :asset
  ]

  def for(%User{} = user, %Organisation{} = org) do
    id = to_string(org.id)

    %__MODULE__{
      id: id,
      user: user,
      organisation: org,
      membership: Organisation.get_membership(org, user)
    }
  end

  @doc """
  Defined a scope for a system
  """
  def for(%User{} = user, %Organisation{} = org, %System{} = system) do
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
