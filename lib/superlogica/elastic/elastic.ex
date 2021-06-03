defmodule Superlogica.Elastic.Elastic do
  require Logger
  alias Elastix.{Document, Index, Search}

  # url elasticsearch
  @elastic_url Application.get_env(:elastix, :elastic_url)

  # índices elasticsearch
  @indexes [
    "superlogica"
  ]

  # insere dados no elasticsearch
  def save(data, index, id) do
    Document.index(@elastic_url, index, ["_doc"], id, data)
    |> handle_save()
  end

  # cria índice no Elasticsearch, caso não exista
  def create_elastic_index(indexes \\ @indexes) when is_list(indexes) do
    indexes
    |> Enum.each(fn index ->
      if {:ok, false} == Index.exists?(@elastic_url, index) do
        Index.create(@elastic_url, index, %{})
      end
    end)
  end

  def search(index, body) do
    Search.search(@elastic_url, index, ["_doc"], body)
  end

  # tokens
  def get_env_from_elastic() do
    body = %{
      query: %{
        match_all: %{}
      },
      fields: ["access_token"],
      _source: false
    }

    search("superlogica_auth", body)
    |> handle_get_env_from_elastic()
  end

  defp handle_get_env_from_elastic(
         {:ok, %HTTPoison.Response{body: %{hits: %{hits: [%{fields: %{token: token}}]}}}}
       ) do
    List.first(token)
  end

  # trata inserções no elasticsearch
  defp handle_save({:ok, %HTTPoison.Response{status_code: status_code}}), do: {:ok, status_code}
  defp handle_save({:error, _}), do: {:error, "Error"}
end
