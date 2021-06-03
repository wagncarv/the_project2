defmodule Superlogica.Helpers.Validate do
  @default_phone_length 9

  def validate_phone(phone) do
    phone
    |> String.replace(~r/[\(\)\+-]/, "")
  end
end
