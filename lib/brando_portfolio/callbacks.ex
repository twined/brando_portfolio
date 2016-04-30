defmodule Brando.Portfolio.Callbacks do
  @moduledoc """
  Execute registered callbacks.

  To register callbacks from your otp_app, add to your otp_app's `config.exs`

      config :brando_portfolio,
        callbacks: %{image_series: %{on_delete: {MyApp.FrontpageSerie, :delete_dependent}}}

  This will call `MyApp.FrontpageSerie.delete_dependent` with the record to be deleted
  as argument.
  """

  @doc """
  Try to execute any registered callbacks
  """
  def execute(schema, type, record) do
    target_fn = get_registered_callbacks(schema, type)
    do_execute(target_fn, record)
  end

  defp do_execute(nil, _) do
    nil
  end

  defp do_execute({module, fun}, record) do
    apply(module, fun, [record])
  end

  defp get_registered_callbacks(schema, type) do
    with callbacks when
         not is_nil(callbacks) <- Application.get_env(:brando_portfolio, :callbacks),
         {:ok, schema_cb}      <- Map.fetch(callbacks, schema),
         {:ok, type_cb}        <- Map.fetch(schema_cb, type),
      do: type_cb
  end
end
