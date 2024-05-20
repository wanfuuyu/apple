defmodule Apple.Rabbitmq.API do
  use HTTPoison.Base

  defp auth_header(username \\ "guest", password \\ "guest") do
    basic_auth = "Basic " <> Base.encode64("#{username}:#{password}")
    # 设置请求头部
    {"Authorization", basic_auth}
  end

  def process_request_headers(headers) do
    headers ++ [auth_header()]
  end

  def process_response_body(binary) do
    case Jason.decode(binary) do
      {:ok, data} -> data
      _ -> ""
    end
  end
end
