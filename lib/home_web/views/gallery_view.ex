defmodule HomeWeb.GalleryView do
  use HomeWeb, :view
  import HomeWeb.GalleryComponents, only: [images: 1, image: 1, banners: 1]
end
