defmodule ThreatShield.Threats do
  @moduledoc """
  The Threats context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Organisations.Membership

  def get_system_with_threats(%User{} = user, org_id, sys_id) do
    query =
      from m in Membership,
        where: m.user_id == ^user.id and m.organisation_id == ^org_id,
        join: o in assoc(m, :organisation),
        join: s in assoc(o, :systems),
        where: s.id == ^sys_id,
        select: s

    Repo.one!(query)
    |> Repo.preload(:organisation)
    |> Repo.preload(:threats)
  end

  @doc """
  Gets a single threat.

  Raises `Ecto.NoResultsError` if the Threat does not exist.

  ## Examples

      iex> get_threat!(123)
      %Threat{}

      iex> get_threat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_threat!(user, threat_id) do
    Repo.one!(get_single_threat_query(user, threat_id))
  end

  @doc """
  Creates a threat.

  ## Examples

      iex> create_threat(%{field: value})
      {:ok, %Threat{}}

      iex> create_threat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_threat(
        %User{} = user,
        %System{} = system,
        %Organisation{} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Threat{}
      |> Threat.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:system, system)

    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.insert!(changeset)
    end)
  end

  @doc """
  Updates a threat.

  ## Examples

      iex> update_threat(threat, %{field: new_value})
      {:ok, %Threat{}}

      iex> update_threat(threat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_threat(%User{} = user, %Threat{} = threat, attrs) do
    changeset =
      threat
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(get_single_threat_query(user, threat.id))
      Repo.update!(changeset)
    end)
  end

  @doc """
  Deletes a threat.

  ## Examples

      iex> delete_threat(threat)
      {:ok, %Threat{}}

      iex> delete_threat(threat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_threat_by_id(%User{} = user, threat_id) do
    Repo.transaction(fn ->
      threat = Repo.one!(get_single_threat_query(user, threat_id))
      Repo.delete(threat)
    end)
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

  def get_single_threat_query(user, threat_id) do
    from m in Membership,
      where: m.user_id == ^user.id,
      join: o in assoc(m, :organisation),
      join: s in assoc(o, :systems),
      join: t in assoc(s, :threats),
      where: t.id == ^threat_id,
      select: t
  end
end
