defmodule ThreatShield.Accounts.RBAC do
  @moduledoc """
  Role Based Access Control (RBAC) for ThreatShield Accounts.
  """

  alias ThreatShield.Accounts.{User, Organisation}

  require Logger

  def verify_permission(%User{} = user, %Organisation{} = organisation, permission) do
    if has_permission(user, organisation, permission) do
      :ok
    else
      :not_allowed
    end
  end

  def verify_permission(%User{} = user, global_permission) do
    if has_permission(user, global_permission) do
      :ok
    else
      :not_allowed
    end
  end

  def has_permission(%User{} = user, permission), do: has_permission(user, nil, permission)

  def has_permission(%User{} = user, _organisation, permission)
      when is_atom(permission) do
    # Logger.debug("Checking permission #{inspect(permission)} for user #{inspect(user)}")

    case permission do
      :administer_platform -> has_global_role(user, :platform_admin)
      _ -> false
    end
  end

  defp has_global_role(%User{} = user, role) when is_binary(role) do
    Enum.member?(user.global_roles, role)
  end

  defp has_global_role(%User{} = user, role) when is_atom(role),
    do: has_global_role(user, Atom.to_string(role))
end
