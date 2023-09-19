defmodule ThreatShield.Members.Rights do
  alias ThreatShield.Organisations.Membership

  @rights %{
    :invite_new_members => [:owner],
    :delete_member => [:owner],
    :edit_membership => [:owner],
    :delete_organisation => [:owner],
    :edit_organisation => [:owner, :editor],
    :create_system => [:owner, :editor],
    :edit_system => [:owner, :editor],
    :delete_system => [:owner, :editor],
    :create_asset => [:owner, :editor],
    :edit_asset => [:owner, :editor],
    :delete_asset => [:owner, :editor],
    :create_mitigation => [:owner, :editor],
    :edit_mitigation => [:owner, :editor],
    :delete_mitigation => [:owner, :editor],
    :create_threat => [:owner, :editor],
    :edit_threat => [:owner, :editor],
    :delete_threat => [:owner, :editor],
    :create_risk => [:owner, :editor],
    :edit_risk => [:owner, :editor],
    :delete_risk => [:owner, :editor]
  }

  def get_authorised_roles(right) do
    Map.get(@rights, right, [])
  end

  def may(right, %Membership{role: role}) do
    role in get_authorised_roles(right)
  end
end
