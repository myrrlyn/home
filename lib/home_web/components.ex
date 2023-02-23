defmodule HomeWeb.Components do
  use Phoenix.Component

  attr :banner, Home.Banners.Banner

  def banner(assigns) do
    assigns =
      unless assigns[:banner],
        do: assign(assigns, :banner, Home.Banners.weighted_random(:main_banners)),
        else: assigns

    ~H"""
    <header
      role="banner"
      class="screen-only"
      title={@banner.caption}
    >
      <style type="text/css">
        header[role="banner"] {
          background-image: url(<%= "/#{@banner}" %>);
          background-position: <%= Home.Banners.Banner.position(@banner) %>;
        }
      </style>
    </header>
    """
  end

  attr :page_title, :string, required: true
  attr :page_subtitle, :string

  def page_title(assigns) do
    ~H"""
    <h1 class="title"><%= @page_title %></h1>
    <h2 :if={assigns[:page_subtitle]} class="title subtitle">
      <%= assigns[:page_subtitle] %>
    </h2>
    """
  end

  embed_templates "components/*"
end
