# Brando Portfolio

[![Coverage Status](https://coveralls.io/repos/github/twined/brando_portfolio/badge.svg?branch=master)](https://coveralls.io/github/twined/brando_portfolio?branch=master)

## Installation

Add brando_portfolio to your list of dependencies in `mix.exs`:

```diff
    def deps do
      [
        {:brando, github: "twined/brando"},
+       {:brando_portfolio, github: "twined/brando_portfolio"}
      ]
    end
```

Install migrations and frontend files:

    $ mix brando.portfolio.install

Run migrations

    $ mix ecto.migrate

Add to your `web/router.ex`:

```diff

    defmodule MyApp.Router do
      use MyApp.Web, :router
      # ...
+     import Brando.Portfolio.Routes.Admin

      scope "/admin", as: :admin do
        pipe_through :admin
        dashboard_routes   "/"
        user_routes        "/users"
+       portfolio_routes   "/portfolio"
      end
    end
```

Add to your `config/brando.exs`:

```diff
    config :brando, Brando.Menu,
      colors: [...],
      modules: [
        Brando.Menu.Admin, 
        Brando.Menu.Users, 
+       Brando.Menu.Portfolio
      ]
```

Add to your `web/static/css/app.scss`:

```diff
  @import
    "includes/colorbox",
    "includes/cookielaw",
    "includes/dropdown",
    "includes/instagram",
-   "includes/nav";
+   "includes/nav",
+   "includes/portfolio";
```

Add to your `web/static/css/custom/brando.custom.scss`

```diff
+ @import
+   "includes/portfolio"
```