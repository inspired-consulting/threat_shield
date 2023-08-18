defmodule ThreatShield.RisksTest do
  use ThreatShield.DataCase

  alias ThreatShield.Risks

  describe "risks" do
    alias ThreatShield.Risks.Risk

    import ThreatShield.RisksFixtures

    @invalid_attrs %{name: nil, description: nil, estimated_cost: nil, probability: nil}

    test "list_risks/0 returns all risks" do
      risk = risk_fixture()
      assert Risks.list_risks() == [risk]
    end

    test "get_risk!/1 returns the risk with given id" do
      risk = risk_fixture()
      assert Risks.get_risk!(risk.id) == risk
    end

    test "create_risk/1 with valid data creates a risk" do
      valid_attrs = %{name: "some name", description: "some description", estimated_cost: 42, probability: 120.5}

      assert {:ok, %Risk{} = risk} = Risks.create_risk(valid_attrs)
      assert risk.name == "some name"
      assert risk.description == "some description"
      assert risk.estimated_cost == 42
      assert risk.probability == 120.5
    end

    test "create_risk/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Risks.create_risk(@invalid_attrs)
    end

    test "update_risk/2 with valid data updates the risk" do
      risk = risk_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", estimated_cost: 43, probability: 456.7}

      assert {:ok, %Risk{} = risk} = Risks.update_risk(risk, update_attrs)
      assert risk.name == "some updated name"
      assert risk.description == "some updated description"
      assert risk.estimated_cost == 43
      assert risk.probability == 456.7
    end

    test "update_risk/2 with invalid data returns error changeset" do
      risk = risk_fixture()
      assert {:error, %Ecto.Changeset{}} = Risks.update_risk(risk, @invalid_attrs)
      assert risk == Risks.get_risk!(risk.id)
    end

    test "delete_risk/1 deletes the risk" do
      risk = risk_fixture()
      assert {:ok, %Risk{}} = Risks.delete_risk(risk)
      assert_raise Ecto.NoResultsError, fn -> Risks.get_risk!(risk.id) end
    end

    test "change_risk/1 returns a risk changeset" do
      risk = risk_fixture()
      assert %Ecto.Changeset{} = Risks.change_risk(risk)
    end
  end
end
