defmodule Superlogica.Messages.Messages do
  alias Superlogica.Messages.ParseFile

  def get_stage(stage, filename \\ "messages.json") do
    ParseFile.build(filename)["stages"]
    |> Map.get("#{stage}")
  end

  # //TODO
  def formatted_message(message) do
    message
  end
end
