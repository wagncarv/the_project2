defmodule Superlogica.Random.RandomValues do
  alias Superlogica.Messages.ParseFile

  # @random_choices [:cpf, :email] //TODO
  @random_choices [:cpf, :email]

  def random_email(email) do
    provider =
      ParseFile.build("options.json")["email_options"]
      |> Enum.shuffle()
      |> Enum.take(1)

    new_email =
      email
      |> String.split("@")
      |> List.first()

    Regex.split(~r{([a-z])}, new_email, include_captures: true)
    |> Enum.reject(fn e -> e == "" end)
    |> Enum.map(fn e -> String.replace(e, ~r/[aeiou]/, random_letter()) end)
    |> List.insert_at(-1, provider)
    |> Enum.join()
  end

  def random_letter do
    Enum.shuffle(["a", "e", "i", "o", "u"])
    |> List.first()
  end

  def random_email_list(email, size \\ 2) do
    Enum.map(1..size, fn _e -> random_email(email) end)
    |> List.insert_at(0, email)
  end

  def random_cpf(cpf) do
    cpf
    |> String.split(~r/[-\/\.\s]/)
    |> Enum.join()

    Regex.split(~r{([0-9])}, cpf, include_captures: true)
    |> Stream.reject(fn e -> e == "" end)
    |> Enum.shuffle()
    |> Enum.join()
  end

  def random_cpf_last_three(cpf) do
    new_cpf = cpf
    |> String.split(~r/[-\/\.\s]/)
    |> Enum.join()
    |> String.slice(8..10)

    Stream.take_every(0..9, 1)
    |> Enum.shuffle()
    |> Enum.chunk_every(3, 4,:discard)
    |> Stream.map(fn e -> Enum.join(e, "") end)
    |> Enum.uniq()
    |> List.insert_at(-1, new_cpf)
    |> Enum.shuffle()
    |> Enum.uniq()

  end

  def random_cpf_list(cpf, size \\ 3) do
    Enum.map(1..size, fn _e -> random_cpf(cpf) end)
  end

  def random_question(%{"cpf" => cpf, "email" => email}, size \\ 3) do
    choice = Enum.shuffle(@random_choices) |> Enum.take(1) |> hd()
    message = random_question_message(choice)
    case choice do
      # :cpf -> %{"message" => message, "key" => "cpf","cpf" => random_cpf_list(cpf, size)}
      :cpf -> %{"message" => message, "key" => "cpf","cpf" => random_cpf_last_three(cpf)}
      :email -> %{"message" => message, "key" => "email", "email" => random_email_list(email, size)}
    end
  end

  defp random_question_message(choice) do
    ParseFile.build("options.json")["random_values_messages"]
    |> Enum.filter(fn e -> e["#{choice}"] end)
    |> hd()
  end
end
