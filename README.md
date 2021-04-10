# myrrlyn.net

This is the server application that drives my website. It contains very little
of the site content, which can be found in my [website-content] repository; this
is limited strictly to the application logic necessary to translate the content
collection into HTTP responses.

It is an [Elixir]/[Phoenix] web application with some custom YAML/Markdown
processing logic and other decorations.

## Installation

```sh
git close https://github.com/myrrlyn/home.git
cd home
mix do deps.get, deps.compile, compile
cd assets
npm install
cd ..
mix phx.server
```

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>

[Elixir]: https://elixir-lang.org/
[Phoenix]: https://www.phoenixframework.org/
[website-content]: https://github.com/myrrlyn/website-content
