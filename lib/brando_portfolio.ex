defmodule Brando.Portfolio do
  @doc """
  Gets the configuration for `module` under :brando_portfolio,
  as set in config.exs
  """
  def config(module), do: Application.get_env(:brando_portfolio, module)
end
