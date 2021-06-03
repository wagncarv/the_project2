defmodule Superlogica.Helpers.Formatters do
  def cpf_format(cpf) do
    [{".", 0..2}, {".", 2..4}, {"-", 4..6}, {"", 6..7}]
    |> Enum.reduce("", fn {sep, range}, format ->
      format <> "#{String.slice(cpf, range)}#{sep}"
    end)
  end

  def cpf_strip_format(cpf) do
    cpf
    |> String.trim()
    |> String.replace(~r/[\.-]/, "")
  end

  def cpf_last_three(cpf) do
    cpf = cpf
    |> cpf_strip_format()
    |> String.slice(8..10)
    [cpf]
  end
end

#08799621789
