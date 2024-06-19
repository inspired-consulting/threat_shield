defmodule ThreatShieldWeb.Router do
  use ThreatShieldWeb, :router

  import ThreatShieldWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ThreatShieldWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ThreatShieldWeb do
    pipe_through :browser

    get "/", WelcomeController, :home
    get "/exports/excel", ExportController, :export_to_excel
  end

  # Other scopes may use custom stacks.
  # scope "/api", ThreatShieldWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:threat_shield, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: ThreatShieldWeb.Telemetry,
        ecto_repos: [ThreatShield.Repo]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ThreatShieldWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ThreatShieldWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
      live "/join/:token", MembersLive.Join, :join
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ThreatShieldWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ThreatShieldWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/organisations", OrganisationLive.MyOrganisations, :index
      live "/organisations/new", OrganisationLive.MyOrganisations, :new
      live "/organisations/:org_id", OrganisationLive.OrganisationDetails, :show
      live "/organisations/:org_id/edit", OrganisationLive.OrganisationDetails, :edit_organisation

      live "/organisations/:org_id/members", MembersLive.Index, :index
      live "/organisations/:org_id/members/new", MembersLive.Index, :new_invite

      live "/organisations/:org_id/risk-board", RiskLive.RiskBoard, :show

      # Systems

      live "/organisations/:org_id/systems/:sys_id", SystemLive.SystemDetails, :show
      live "/organisations/:org_id/systems/:sys_id/edit", SystemLive.SystemDetails, :edit_system
      live "/organisations/:org_id/systems/:sys_id/show/edit", SystemLive.SystemDetails, :edit

      # Assets

      live "/organisations/:org_id/systems/:sys_id/assets/:asset_id",
           AssetLive.AssetDetails,
           :show

      live "/organisations/:org_id/systems/:sys_id/assets/:asset_id/show/edit",
           AssetLive.AssetDetails,
           :edit

      live "/organisations/:org_id/assets/:asset_id", AssetLive.AssetDetails, :show
      live "/organisations/:org_id/assets/:asset_id/show/edit", AssetLive.AssetDetails, :edit

      # Threats

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/new",
           ThreatLive.ThreatDetails,
           :new_risk

      live "/organisations/:org_id/systems/:sys_id/assets/:asset_id/threats/:threat_id",
           ThreatLive.ThreatDetails,
           :show

      live "/organisations/:org_id/assets/:asset_id/threats/:threat_id",
           ThreatLive.ThreatDetails,
           :show

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id",
           ThreatLive.ThreatDetails,
           :show

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/edit",
           ThreatLive.ThreatDetails,
           :edit_threat

      live "/organisations/:org_id/threats/:threat_id/edit",
           ThreatLive.ThreatDetails,
           :edit_threat

      live "/organisations/:org_id/threats/:threat_id", ThreatLive.ThreatDetails, :show

      live "/organisations/:org_id/threats/:threat_id/show/edit",
           ThreatLive.ThreatDetails,
           :edit

      # Risks

      live "/organisations/:org_id/threats/:threat_id/risks/new",
           ThreatLive.ThreatDetails,
           :new_risk

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id", RiskLive.RiskDetails, :show

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/edit",
           RiskLive.RiskDetails,
           :edit_risk

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id",
           RiskLive.RiskDetails,
           :show

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/edit",
           RiskLive.RiskDetails,
           :edit_risk

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/mitigations/new",
           RiskLive.RiskDetails,
           :new_mitigation

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/new",
           RiskLive.RiskDetails,
           :new_mitigation

      # Mitigations

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id",
           MitigationLive.MitigationDetails,
           :show

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id",
           MitigationLive.MitigationDetails,
           :show

      live "/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id/edit",
           MitigationLive.MitigationDetails,
           :edit_mitigation

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id/edit",
           MitigationLive.MitigationDetails,
           :edit_mitigation
    end

    live_session :platform_admin,
      on_mount: [{ThreatShieldWeb.UserAuth, :ensure_authenticated}],
      layout: {ThreatShieldWeb.Layouts, :admin} do
      live "/platform-administration/organisations", AdminLive.OrganisationsManagement, :index
    end
  end

  scope "/", ThreatShieldWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ThreatShieldWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
