defmodule Superlogica.Messages.ParseFile do
  def parse_file(filename \\ "messages.json") do
    "priv/files/#{filename}"
    |> File.stream!()
  end

  def build(filename \\ "messages.json") do
    filename
    |> parse_file()
    |> Enum.to_list()
    |> Enum.join("")
    |> Jason.decode!()
  end
end
