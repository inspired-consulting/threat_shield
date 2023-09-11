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

    get "/", PageController, :home
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

      live_dashboard "/dashboard", metrics: ThreatShieldWeb.Telemetry
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
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ThreatShieldWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ThreatShieldWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/dashboard", DashboardLive.Index, :index

      live "/organisations", OrganisationLive.Index, :index
      live "/organisations/new", OrganisationLive.Index, :new
      live "/organisations/:org_id", OrganisationLive.Show, :show
      live "/organisations/:org_id/edit", OrganisationLive.Index, :edit

      live "/organisations/:org_id/dashboard", DashboardLive.Index, :index

      live "/organisations/:org_id/systems", SystemLive.Index, :index
      live "/organisations/:org_id/systems/new", SystemLive.Index, :new
      live "/organisations/:org_id/systems/:sys_id/edit", SystemLive.Index, :edit

      live "/organisations/:org_id/systems/:sys_id", SystemLive.Show, :show
      live "/organisations/:org_id/systems/:sys_id/show/edit", SystemLive.Show, :edit

      live "/organisations/:org_id/threats", ThreatLive.Index, :index
      live "/organisations/:org_id/threats/new", ThreatLive.Index, :new

      live "/organisations/:org_id/threats/:threat_id/edit",
           ThreatLive.Show,
           :edit_threat

      live "/organisations/:org_id/threats/:threat_id", ThreatLive.Show, :show

      live "/organisations/:org_id/threats/:threat_id/show/edit",
           ThreatLive.Show,
           :edit

      live "/organisations/:org_id/threats/:threat_id/risks/new", ThreatLive.Show, :new_risk

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/edit",
           RiskLive.Show,
           :edit_risk

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id", RiskLive.Show, :show

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations",
           MitigationLive.Index,
           :index

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/new",
           RiskLive.Show,
           :new_mitigation

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id/edit",
           MitigationLive.Index,
           :edit

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id",
           MitigationLive.Show,
           :show

      live "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id/show/edit",
           MitigationLive.Show,
           :edit_mitigation

      live "/organisations/:org_id/assets", AssetLive.Index, :index
      live "/organisations/:org_id/assets/new", AssetLive.Index, :new
      live "/organisations/:org_id/assets/:asset_id/edit", AssetLive.Index, :edit

      live "/organisations/:org_id/assets/:asset_id", AssetLive.Show, :show
      live "/organisations/:org_id/assets/:asset_id/show/edit", AssetLive.Show, :edit
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
