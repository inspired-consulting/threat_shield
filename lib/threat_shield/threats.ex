defmodule ThreatShield.Threats do
  @moduledoc """
  The Threats context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias ThreatShield.Repo

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System

  def get_organisation!(%User{} = user, org_id) do
    Organisations.get_organisation!(user, org_id)
    |> Repo.preload(threats: :system)
    |> Repo.preload(:systems)
  end

  def get_threat!(%User{id: user_id}, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user_id)
    |> Repo.one!()
    |> Repo.preload(:organisation)
    |> Repo.preload(:system)
  end

  def create_threat(
        %User{} = user,
        %Organisation{} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Threat{organisation: organisation}
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_threat_changeset(changeset, user)
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.insert!(changeset)
    end)
  end

  def add_threat_by_id(%User{} = user, threat_id) do
    Repo.transaction(fn ->
      changeset =
        Repo.one!(get_single_threat_query(user, threat_id))
        |> Repo.preload(:organisation)
        |> Threat.changeset(%{is_candidate: false})

      Repo.update!(changeset)
    end)
  end

  def bulk_add_for_user_and_org(%User{} = user, %Organisation{} = organisation, threats) do
    multi =
      Multi.new()
      |> Multi.exists?(:check_access, Organisations.is_member_query(user, organisation))

    threat_changesets =
      Enum.map(
        threats,
        fn threat ->
          Ecto.Changeset.change(threat)
          |> Ecto.Changeset.put_assoc(:organisation, organisation)
        end
      )

    {:ok, result} =
      Enum.reduce(
        threat_changesets,
        multi,
        fn changeset, acc ->
          Multi.insert(
            acc,
            {:insert_threat, changeset},
            changeset
          )
        end
      )
      |> Repo.transaction()

    result
    |> Enum.filter(fn {k, _v} ->
      case k do
        {:insert_threat, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {_k, v} -> v end)
  end

  def update_threat(%User{} = user, %Threat{} = threat, attrs) do
    changeset =
      threat
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      check_related_system_in_threat_changeset(changeset, user)
      Repo.one!(get_single_threat_query(user, threat.id))
      Repo.update!(changeset)
    end)
  end

  def delete_threat_by_id(%User{} = user, threat_id) do
    case Repo.delete_all(get_single_threat_query(user, threat_id)) do
      {1, _} -> {:ok, 1}
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking threat changes.

  ## Examples

      iex> change_threat(threat)
      %Ecto.Changeset{data: %Threat{}}

  """
  def change_threat(%Threat{} = threat, attrs \\ %{}) do
    Threat.changeset(threat, attrs)
  end

  defp check_related_system_in_threat_changeset(%{changes: %{system_id: sys_id}}, user)
       when not is_nil(sys_id) do
    System.get(sys_id)
    |> System.for_user(user.id)
    |> Repo.one!()
  end

  defp check_related_system_in_threat_changeset(_, _user) do
  end

  def get_single_threat_query(user, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user.id)
  end
end
