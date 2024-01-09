defmodule ThreatShieldWeb.Icons do
  @moduledoc """
  Provides icons as components
  """
  use Phoenix.Component

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def heroicon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  attr :class, :string, default: nil

  def app_icon(assigns) do
    ~H"""
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
    >
      <path
        d="M20.33 56.48L31.43 61.04C31.61 61.11 31.81 61.15 32 61.15C32.19 61.15 32.39 61.11 32.57 61.04L43.67 56.48C50.86 53.53 55.5 46.85 55.5 39.45V14.2C55.5 13.37 54.83 12.7 54 12.7C53.9 12.7 43.45 12.59 33 3.23C32.43 2.72 31.57 2.72 31 3.23C20.6 12.55 10.1 12.7 10 12.7C9.17 12.7 8.5 13.37 8.5 14.2V39.45C8.5 46.85 13.14 53.53 20.33 56.48ZM11.5 15.61C14.86 15.27 23.32 13.68 32 6.34C40.69 13.68 49.15 15.27 52.5 15.61V39.46C52.5 45.63 48.59 51.23 42.53 53.71L32 58.03L21.47 53.71C15.41 51.23 11.5 45.63 11.5 39.46V15.61Z"
        fill="currentColor"
      />
      <path d="M21.94 42.23H26.21V27.8H31.53V24.5H16.71V27.8H21.94V42.23Z" fill="currentColor" />
      <path
        d="M41.54 38.8C41.13 39.1 40.57 39.26 39.87 39.26C38.77 39.26 37.97 39.03 37.48 38.58C36.99 38.13 36.74 37.43 36.74 36.48H32.46C32.46 37.65 32.75 38.68 33.34 39.58C33.93 40.48 34.8 41.18 35.97 41.7C37.13 42.22 38.44 42.47 39.87 42.47C41.91 42.47 43.51 42.03 44.68 41.14C45.85 40.26 46.43 39.04 46.43 37.49C46.43 35.55 45.47 34.03 43.56 32.93C42.77 32.48 41.77 32.05 40.54 31.66C39.31 31.27 38.46 30.89 37.97 30.52C37.48 30.15 37.24 29.74 37.24 29.28C37.24 28.76 37.46 28.33 37.9 28C38.34 27.67 38.94 27.49 39.71 27.49C40.48 27.49 41.06 27.69 41.51 28.09C41.96 28.49 42.17 29.05 42.17 29.77H46.43C46.43 28.69 46.15 27.73 45.59 26.89C45.03 26.05 44.25 25.4 43.23 24.95C42.22 24.5 41.08 24.27 39.8 24.27C38.52 24.27 37.32 24.48 36.27 24.9C35.22 25.32 34.41 25.9 33.84 26.65C33.27 27.4 32.98 28.27 32.98 29.25C32.98 31.22 34.13 32.77 36.42 33.9C37.13 34.25 38.03 34.61 39.15 34.98C40.26 35.35 41.04 35.71 41.48 36.06C41.92 36.41 42.14 36.9 42.14 37.52C42.14 38.07 41.93 38.5 41.53 38.8H41.54Z"
        fill="currentColor"
      />
    </svg>
    """
  end
end
