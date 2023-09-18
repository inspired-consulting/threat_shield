defmodule ThreatShield.Members.Rights do
  alias ThreatShield.Organisations.Membership

  @rights %{
    :invite_new_members => [:owner],
    :delete_member => [:owner],
    :edit_membership => [:owner],
    :delete_organisation => [:owner],
    :edit_organisation => [:owner, :editor]
  }

  def get_authorised_roles(right) do
    Map.get(@rights, right, [])
  end

  def may(right, %Membership{role: role}) do
    role in get_authorised_roles(right)
  end
end
