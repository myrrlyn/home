defmodule HomeWeb.GalleryComponents do
  @moduledoc """
  Contains HTML snippets used in the image galleries.
  """

  use Phoenix.Component

  @doc """
  Renders a single image to HTML, with a hover title, a caption, and a resource
  path.
  """
  def image(%{title: title, caption: caption, path: path} = assigns) do
    ~H"""
    <div class="img-block">
      <!-- <img src={path} title={title} alt={title} class="unset gallery-img" /> -->
      <div class="async-image" data-src={path} data-title={title}>
      </div>
      <p class="img-caption"><%= caption %></p>
    </div>
    """
  end

  @doc """
  Renders a collection of images under a heading.
  """
  def images(%{heading: heading, images: images, root: root} = assigns) do
    ~H"""
    <%= if heading && heading != "" do %>
      <h2><%= heading %></h2>
    <% end %>
    <div class="container d-flex flex-wrap">
      <%= for %Home.Banners.Banner{caption: caption, path: path} <- images do %>
        <.image title={caption} caption={caption} path={[root, path] |> Path.join} />
      <% end %>
    </div>
    """
  end
end
