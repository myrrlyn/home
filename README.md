# myrrlyn.net

This is the server application that drives my website. It contains very little
of the site content, which can be found in my [website-content] repository; this
is limited strictly to the application logic necessary to translate the content
collection into HTTP responses.

It is an [Elixir]/[Phoenix] web application with some custom YAML/Markdown
processing logic and other decorations.

## Installation

```sh
git clone https://github.com/myrrlyn/home.git
cd home
mix do deps.get, deps.compile, compile
cd assets
npm install
cd ..
mix phx.server
```

## Markdown

This renders markdown documents with a YAML frontmatter and support for inline
attribute lists, with some additional behaviors.

The `{:tag="html tag"}` attribute replaces the HTML tag that Markdown chose to
parse (currently supported: `blockquote`, `code`, and `p`) with whatever tag is
desired. I use this to supply `figure`, `figcaption`, `cite`, and `aside`
elements.

The frontmatter supports tab titles, page titles, and page subtitles, as well as
other metadata such as publishing date, resource embeds, and content tags. These
are used to fill in portions of the page framework, and to inject foreign
libraries like MathJax.

## Banner Images

Pages can choose their banner image by setting the `banner:` or `album:` key in
the frontmatter. These must correspond to objects in `assets/banners.toml`. When
`banner:` is set, only that banner will be served on the page; when `album:` is
set, an image will be randomly selected from the named collection.

## Caching

The library I was using to manage content cache headers such as ETag and
Last-Modified is not maintained and no longer works with modern Phoenix. As
such, I currently do not emit cache-control headers or serve opportunistic 304
responses for the main content of a page.

I am working on it.

## Style

The page layout is supposed to be responsive to mobile devices, and I test it on
both my laptop and my phone. If you have complaints about the CSS, please let me
know and I’ll try to address them. I am _decent_, though unimaginative, at CSS,
and am always open to feedback and improvement.

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>

[Elixir]: https://elixir-lang.org/
[Phoenix]: https://www.phoenixframework.org/
[website-content]: https://github.com/myrrlyn/website-content
