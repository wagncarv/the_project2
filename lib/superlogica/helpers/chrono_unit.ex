defmodule Superlogica.Helpers.ChronoUnit do
  require Logger
  use Timex

  @current_date Date.utc_today()
  @current_day @current_date.day
  @current_month @current_date.month
  @current_year @current_date.year

  @time_now Time.utc_now().hour

  @month_shortname [
    "Jan",
    "Fev",
    "Mar",
    "Abr",
    "Mai",
    "Jun",
    "Jul",
    "Ago",
    "Set",
    "Out",
    "Nov",
    "Dez"]

  @month_fullname [
    {1, "Janeiro"},
    {2, "Fevereiro"},
    {3, "Março"},
    {4, "Abril"},
    {5, "Maio"},
    {6, "Junho"},
    {7, "Julho"},
    {8, "Agosto"},
    {9, "Setembro"},
    {10, "Outubro"},
    {11, "Novembro"},
    {12, "Dezembro"}
  ]

  #
  def convert(date) do
    [month, day, year | _] = String.split(date, ~r/[\/\s]/)

    Timex.parse!("#{year}-#{month}-#{day}", "{YYYY}-{0M}-{D}")
    |> Timex.to_datetime()
  end

  def to_custom_pattern(date, pattern \\ "{YYYY}-{0M}-{D}") do
    date
    |> String.split("/")
    |> Enum.reverse()
    |> Enum.join("-")
    |> Date.from_iso8601!()
    |> Timex.format!(pattern)
  end

  def custom_format(date, splitter \\ "-") do
    [month, day, year] = date
    |> String.trim()
    |> String.split(splitter)
    "#{day}/#{month}/#{year}"
  end

  # formatação sem validação de data
  # formata de mm/dd/yyy para dd/mm/yyyy
  def naive_format(date) do
    [month, day, year] = date
    |> String.replace(~r/ 00:00:00/, "")
    |> String.split("/")
    "#{day}/#{month}/#{year}"
  end

  # formatação sem validação de data
  # formata de mm/dd/yyy para dd/mm/yyyy
  def simple_naive_format(date) do
    [month, day, year] = date
    |> String.split("/")
    "#{day}/#{month}/#{year}"
  end

  # formatação sem validação de data
  # formata de mm/dd/yyy para dd/mm/yyyy
  def simple_naive_format(day, month) do
    "#{day}/#{month}/#{@current_date.year}"
    |> String.pad_leading(10, "0")
  end

  def spawn_from_naive(day, month) do
    "#{month}/#{day}/#{@current_date.year}"
    |> simple_naive_format()
  end

  def format_today_to_custom, do: "#{@current_date.month}/#{@current_date.day}/#{@current_date.year}"

  # gera lista de datas baseadas no mês
  def list_of_dates(month) when month < 1 or month > 12, do: {:error, "Month #{month} is invalid"}

  def list_of_dates(month) when month < @current_month,
    do: {:error, "Month #{month} is before current month"}

  def list_of_dates(month) when month == @current_month do
    date_range(@current_date, Timex.end_of_month(@current_year, month))
  end

  def list_of_dates(month) when month > @current_month do
    date_range(
      Timex.beginning_of_month(@current_year, month),
      Timex.end_of_month(@current_year, month)
    )
  end

  def list_of_dates(), do: {:error, "Month is empty"}

  def list_of_months, do:  Enum.map(@current_date.month .. 12, fn e -> e end)

  def month_short_name(month) when month > 0, do: Enum.fetch!(@month_shortname, month - 1)

  def months_fullname do
    Enum.filter(@month_fullname, fn {month, _month_name} ->
      month >= @current_month
    end)
    |> Enum.reduce("", fn {month, name}, str -> "#{str}#{month} - #{name}\n" end)
  end


  # gera uma faixa de datas
  defp date_range(begin, last) do
    Date.range(begin, last)
    |> Enum.map(fn date -> date end)
  end

  def greeting(time \\ @time_now) do
    cond do
      time >= 0 and time < 6 -> "Boa noite"
      time >= 6 and time < 12 -> "Bom dia"
      time >= 12 and time < 18 -> "Boa tarde"
      time >= 18 and time <= 23 -> "Boa noite"
    end
  end

  def today, do: "#{@current_day}/#{@current_month}/#{@current_year}"
  def custom_today, do: "#{@current_month}/#{@current_day}/#{@current_year}"
  def beginning_of_year, do: "01/01/#{@current_year}"

  def period_range_dates(begin_date, minimum_before \\ 1, max_after \\ 30) do
    min_date_limit = Date.add(begin_date, minimum_before)
    max_date_limit = Date.add(min_date_limit, max_after)
    Date.range(min_date_limit, max_date_limit)
  end
end
