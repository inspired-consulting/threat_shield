defmodule ThreatShieldWeb.ErrorJSON do
  # If you want to customize a particular is_candidate code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the is_candidate message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.is_candidate_message_from_template(template)}}
  end
end
