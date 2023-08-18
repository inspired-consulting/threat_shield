defmodule ThreatShield.Risks do
  @moduledoc """
  The Risks context.
  """

  import Ecto.Query, warn: false
  alias ThreatShield.Repo

  alias ThreatShield.Risks.Risk

  @doc """
  Returns the list of risks.

  ## Examples

      iex> list_risks()
      [%Risk{}, ...]

  """
  def list_risks do
    Repo.all(Risk)
  end

  @doc """
  Gets a single risk.

  Raises `Ecto.NoResultsError` if the Risk does not exist.

  ## Examples

      iex> get_risk!(123)
      %Risk{}

      iex> get_risk!(456)
      ** (Ecto.NoResultsError)

  """
  def get_risk!(id), do: Repo.get!(Risk, id)

  @doc """
  Creates a risk.

  ## Examples

      iex> create_risk(%{field: value})
      {:ok, %Risk{}}

      iex> create_risk(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_risk(attrs \\ %{}) do
    %Risk{}
    |> Risk.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a risk.

  ## Examples

      iex> update_risk(risk, %{field: new_value})
      {:ok, %Risk{}}

      iex> update_risk(risk, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_risk(%Risk{} = risk, attrs) do
    risk
    |> Risk.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a risk.

  ## Examples

      iex> delete_risk(risk)
      {:ok, %Risk{}}

      iex> delete_risk(risk)
      {:error, %Ecto.Changeset{}}

  """
  def delete_risk(%Risk{} = risk) do
    Repo.delete(risk)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking risk changes.

  ## Examples

      iex> change_risk(risk)
      %Ecto.Changeset{data: %Risk{}}

  """
  def change_risk(%Risk{} = risk, attrs \\ %{}) do
    Risk.changeset(risk, attrs)
  end
end
