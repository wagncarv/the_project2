defmodule Superlogica.Storage.Storage do
  require Logger
  alias ETS.Set

  def new_storage(
        opts \\ [
          name: :storage,
          read_concurrency: true,
          write_concurrency: true,
          protection: :public
        ]
      ) do
    Set.new(opts)
  end
  
  def insert(data, table_name \\ :storage) do
    Logger.info("#{__MODULE__}.insert/2", ansi_color: :blue)
    :ets.insert(table_name, data)
  end

  def update(data, key, position \\ 3, table_name \\ :storage) do
    Logger.info("#{__MODULE__}.update/3", ansi_color: :blue)
    :ets.update_element(table_name, key, {position, data})
  end

  def get(key, table_name \\ :storage) do
    Logger.info("#{__MODULE__}.get/2", ansi_color: :blue)

    :ets.lookup(table_name, key)
    |> List.first()
  end

  def delete(key, table_name \\ :storage) do
    Logger.info("#{__MODULE__}.delete/2", ansi_color: :blue)
    :ets.delete(table_name, key)
  end

  def delete_table(table_name) do
    Logger.info("#{__MODULE__}.delete_table/1", ansi_color: :blue)
    :ets.delete(table_name)
  end
end
