defmodule Superlogica.Helpers.Headers do
  @headers [
    {"Content-Type", "application/json"},
    {"app_token", "d2878a86-ba85-3a97-a952-a22eae8482ad"},
    {"access_token", "f6b0fa44-d291-3c28-9354-78925a42cffa"}
  ]

  @header_urlencoded [
    {"Content-Type", "application/x-www-form-urlencoded"},
    {"app_token", "d2878a86-ba85-3a97-a952-a22eae8482ad"},
    {"access_token", "f6b0fa44-d291-3c28-9354-78925a42cffa"}
  ]

  def headers, do: @headers

  def header_urlencoded, do: @header_urlencoded
end

# algol
# {"app_token", "d2878a86-ba85-3a97-a952-a22eae8482ad"},
# {"access_token", "f6b0fa44-d291-3c28-9354-78925a42cffa"}

# {"app_token", "e0c6a266-456c-3ad7-a510-22e64e8e9f89"},
# {"access_token", "669f4bc6-c0ce-3590-af15-bfdae4bf8c36"}
