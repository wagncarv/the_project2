defmodule Superlogica.Env.Env do
  def put_to_env(enum) do
    System.put_env(enum)
  end

  # atualiza variável de ambiente
  def put_to_env(var_name, value) do
    System.put_env(var_name, value)
  end

  def get_from_env(var_name) do
    System.fetch_env(var_name)
  end
end
