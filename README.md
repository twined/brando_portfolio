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

    $ mix brando_portfolio.install

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

Add to your `lib/my_app.ex`:

```diff
    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      children = [
        # Start the endpoint when the application starts
        supervisor(MyApp.Endpoint, []),
        # Start the Ecto repository
        supervisor(MyApp.Repo, []),
        # Here you could define other workers and supervisors as children
        # worker(MyApp.Worker, [arg1, arg2, arg3]),
      ]

+     Brando.Registry.register(Brando.Portfolio)
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
+   "includes/portfolio";
```

Add to your `web/static/js/admin/index.js`

```javascript
import Portfolio from './portfolio';

$(() => {
  switch ($('body').attr('data-script')) {
  // ...
  case 'portfolio-index':
    Portfolio.setup();
    break;
  case 'portfolio-upload':
    Portfolio.setupUpload();
    break;
  }
});

```

## Default image series Villain data

Add to your otp_app's `config.exs`:

    config :brando_portfolio,
      default_image_series_data: ~s([{"type":"markdown","data":{"text":"Default description"}}])

## Callbacks

To register callbacks from your otp_app, add to your otp_app's `config.exs`

    config :brando_portfolio,
      callbacks: %{image_series: %{on_delete: {MyApp.FrontpageSerie, :delete_dependent}}}

This will call `MyApp.FrontpageSerie.delete_dependent` with the record to be deleted
as argument.
