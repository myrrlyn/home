defmodule HomeWeb.Components do
  use Phoenix.Component

  def banner(%{banner: %Home.Banners.Banner{} = banner, path: path} = assigns) do
    ~H"""
    <header
      role="banner"
      class="screen-only"
      title={banner.caption}
    >
      <style type="text/css">
        header[role="banner"] {
          background-image: url(<%= path %>);
          background-position: <%= Home.Banners.Banner.position(banner) %>;
        }
      </style>
    </header>
    """
  end
end
