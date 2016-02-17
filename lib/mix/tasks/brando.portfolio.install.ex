defmodule Mix.Tasks.BrandoPortfolio.Install do
  use Mix.Task
  import Mix.Generator

  @moduledoc """
  Install Brando.
  """

  @shortdoc "Generates files for Brando Portfolio."

  @new [
    # Migration files
    {:eex,  "templates/brando.portfolio.install/priv/repo/migrations/portfolio_frontpage_photos_migration.exs",
            "priv/repo/migrations/timestamp_create_portfolio_frontpage_photos.exs"},
    {:eex,  "templates/brando.portfolio.install/priv/repo/migrations/portfolio_imagecategories_migration.exs",
            "priv/repo/migrations/timestamp_create_portfolio_imagecategories.exs"},
    {:eex,  "templates/brando.portfolio.install/priv/repo/migrations/portfolio_images_migration.exs",
            "priv/repo/migrations/timestamp_create_portfolio_images.exs"},
    {:eex,  "templates/brando.portfolio.install/priv/repo/migrations/portfolio_imageseries_migration.exs",
            "priv/repo/migrations/timestamp_create_portfolio_imageseries.exs"},

    # Frontend controllers
    {:eex,  "templates/brando.portfolio.install/web/controllers/portfolio/image_category_controller.ex",
            "web/controllers/portfolio/image_category_controller.ex"},
    {:eex,  "templates/brando.portfolio.install/web/controllers/portfolio/image_controller.ex",
            "web/controllers/portfolio/image_controller.ex"},
    {:eex,  "templates/brando.portfolio.install/web/controllers/portfolio/image_series_controller.ex",
            "web/controllers/portfolio/image_series_controller.ex"},

    # Frontend templates
    {:eex,  "templates/brando.portfolio.install/web/templates/portfolio/image/show.html.eex",
            "web/templates/portfolio/image/show.html.eex"},
    {:eex,  "templates/brando.portfolio.install/web/templates/portfolio/image_category/index.html.eex",
            "web/templates/portfolio/image_category/index.html.eex"},
    {:eex,  "templates/brando.portfolio.install/web/templates/portfolio/image_category/latest.html.eex",
            "web/templates/portfolio/image_category/latest.html.eex"},
    {:eex,  "templates/brando.portfolio.install/web/templates/portfolio/image_category/show.html.eex",
            "web/templates/portfolio/image_category/show.html.eex"},
    {:eex,  "templates/brando.portfolio.install/web/templates/portfolio/image_series/show.html.eex",
            "web/templates/portfolio/image_series/show.html.eex"},

    # Frontend views
    {:eex,  "templates/brando.portfolio.install/web/views/portfolio/image_category_view.ex",
            "web/views/portfolio/image_category_view.ex"},
    {:eex,  "templates/brando.portfolio.install/web/views/portfolio/image_series_view.ex",
            "web/views/portfolio/image_series_view.ex"},
    {:eex,  "templates/brando.portfolio.install/web/views/portfolio/image_view.ex",
            "web/views/portfolio/image_view.ex"},

    # Backend css
    {:copy, "templates/brando.portfolio.install/web/static/css/custom/includes/_portfolio.scss",
            "web/static/css/custom/includes/_portfolio.scss"},

    # Frontend css
    {:copy, "templates/brando.portfolio.install/web/static/css/includes/_portfolio.scss",
            "web/static/css/includes/_portfolio.scss"},

    # Backend js
    {:copy, "templates/brando.portfolio.install/web/static/js/admin/portfolio.js",
            "web/static/js/admin/portfolio.js"},

    # Vendor js
    {:copy, "templates/brando.portfolio.install/web/static/js/vendor/imagesloaded.pkgd.js",
            "web/static/js/vendor/imagesloaded.pkgd.js"},
    {:copy, "templates/brando.portfolio.install/web/static/js/vendor/masonry.pkgd.js",
            "web/static/js/vendor/masonry.pkgd.js"},

  ]

  @static []

  @root Path.expand("../../../priv", __DIR__)

  for {format, source, _} <- @new ++ @static do
    unless format in [:keep, :copy] do
      @external_resource Path.join(@root, source)
      def render(unquote(source)), do: unquote(File.read!(Path.join(@root, source)))
    end
  end

  def run(_) do
    app = Mix.Project.config()[:app]
    binding = [application_module: Phoenix.Naming.camelize(Atom.to_string(app)),
               application_name: Atom.to_string(app)]

    copy_from "./", binding, @new

    Mix.shell.info "\nBrando Portfolio finished installing."
  end

  defp copy_from(target_dir, binding, mapping) when is_list(mapping) do
    application_name = Keyword.fetch!(binding, :application_name)
    for {format, source, target_path} <- mapping do
      target_path =
        target_path
        |> String.replace("application_name", application_name)
        |> String.replace("timestamp", timestamp())
      target = Path.join(target_dir, target_path)

      case format do
        :eex  -> contents = EEx.eval_string(render(source), binding, file: source)
                 create_file(target, contents)
        :copy -> File.mkdir_p!(Path.dirname(target))
                 File.copy!(Path.join(@root, source), target)
      end
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end