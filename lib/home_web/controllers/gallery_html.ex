defmodule HomeWeb.GalleryHTML do
  use HomeWeb, :html

  @doc """
  Renders a single image to HTML, with a hover title, a caption, and a resource
  path.
  """
  attr :path, :string, required: true
  attr :title, :string, required: true
  attr :caption, :string, required: true

  def image(assigns) do
    ~H"""
    <div class="img-block">
      <!-- <img src={path} title={title} alt={title} class="unset gallery-img" /> -->
      <div class="async-image" data-src={@path} data-title={@title}>
      </div>
      <p class="img-caption"><%= @caption %></p>
    </div>
    """
  end

  @doc """
  Renders a collection of images under a heading.
  """
  attr :heading, :string, default: ""
  attr :root, :string, required: true
  attr :images, :any, required: true

  def images(assigns) do
    ~H"""
    <h2 :if={@heading != ""}><%= @heading %></h2>
    <div class="container d-flex flex-wrap">
      <.image
        :for={path <- @images}
        title={path}
        caption={path}
        path={Path.join(@root, path)}
      />
    </div>
    """
  end

  attr :heading, :string, default: ""
  attr :images, :any, required: true
  attr :root, :string, required: true

  def banners(assigns) do
    ~H"""
    <h2 :if={@heading != ""}><%= Home.Banners.album_name(@heading) %></h2>
    <div class="container d-flex flex-wrap">
      <.image
        :for={%Home.Banners.Banner{caption: caption, file: path} <- @images}
        title={caption}
        caption={caption}
        path={Path.join(@root, path)}
      />
    </div>
    """
  end

  embed_templates "gallery_html/*"
end
