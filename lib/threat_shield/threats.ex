defmodule ThreatShield.Threats do
  @moduledoc """
  The Threats context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Organisations.Membership

  def get_organisation_with_threats(%User{} = user, org_id) do
    query =
      from m in Membership,
        where: m.user_id == ^user.id and m.organisation_id == ^org_id,
        join: o in assoc(m, :organisation),
        select: o

    Repo.one!(query)
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
    |> Repo.preload(:organisation)
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
        %Organisation{} = organisation,
        attrs \\ %{}
      ) do
    changeset =
      %Threat{organisation: organisation}
      |> Threat.changeset(attrs)

    Repo.transaction(fn ->
      Repo.one!(Organisations.is_member_query(user, organisation))
      Repo.insert!(changeset)
    end)
  end

  def ignore_threat_by_id(%User{} = user, threat_id) do
    update_acceptance_for_id(user, threat_id, false)
  end

  def add_threat_by_id(%User{} = user, threat_id) do
    update_acceptance_for_id(user, threat_id, true)
  end

  defp update_acceptance_for_id(%User{} = user, threat_id, target_value) do
    Repo.transaction(fn ->
      changeset =
        Repo.one!(get_single_threat_query(user, threat_id))
        |> Repo.preload(:organisation)
        |> Threat.changeset(%{is_accepted: target_value})

      Repo.update!(changeset)
    end)
  end

  def bulk_add_for_user_and_org(%User{} = user, %Organisation{} = organisation, threats) do
    Repo.transaction(fn ->
      Organisations.get_organisation_for_user!(user, organisation.id)

      Enum.each(threats, fn threat ->
        changeset =
          threat
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:organisation, organisation)

        Repo.insert!(changeset)
      end)
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
    IO.inspect(user)

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

  def get_single_threat_query(user, threat_id) do
    Threat.get(threat_id)
    |> Threat.for_user(user.id)
  end
end
