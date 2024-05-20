defmodule Apple.Rabbitmq do
  use HTTPoison.Base

  alias Apple.Rabbitmq.Single
  alias Apple.Rabbitmq.Cluster

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

  @doc """
  detect Single and Cluster and then return one 
  """
  def connection_url() do
    case Single.is_running() do
      true ->
        {:ok, Single.connection_url()}

      false ->
        {:ok, "amqp://guest:guest@localhost"}
    end
  end

  def api() do
    case Single.is_running() do
      true ->
        {:ok, Single.api()}

      _ ->
        # using external
        {:ok, "http://localhost:15672/api"}
    end
  end

  def delete_obj(_api = "", type, obj) do
    {:ok, api} = api()
    do_delete(api, type, obj)
  end

  def delete_obj(api, type, obj) do
    do_delete(api, type, obj)
  end

  def list_obj(_api = "", type) do
    {:ok, api} = api()
    do_list(api, type)
  end

  def list_obj(api, type) do
    do_list(api, type)
  end

  def get_obj(_api = "", type, obj) do
    {:ok, api} = api()
    do_get(api, type, obj)
  end

  def get_obj(api, type, obj) do
    do_get(api, type, obj)
  end

  defp do_list(api, type) do
    case type do
      :connections ->
        {:ok, response} = get(api <> "/connections")
        {:ok, response.body}

      :queues ->
        {:ok, response} = get(api <> "/queues")
        {:ok, response.body}

      :channels ->
        {:ok, response} = get(api <> "/channels")
        {:ok, response.body}

      :vhosts ->
        {:ok, response} = get(api <> "/vhosts")
        {:ok, response.body}

      :exchanges ->
        {:ok, response} = get(api <> "/exchanges")
        {:ok, response.body}

      _ ->
        {:not_supported, ""}
    end
  end

  defp do_get(api, type, obj) do
    case type do
      :exchange_binding_queues ->
        {:ok, bindings} = get(api <> "/exchanges/%2F/#{obj}/bindings/source")

        names =
          Enum.map(bindings.body, fn binding ->
            binding["destination"]
          end)

        {:ok, queues} = get(api <> "/queues")

        filtered_queues =
          Enum.filter(queues.body, fn queue ->
            Enum.member?(names, queue["name"])
          end)

        {:ok, filtered_queues}

      :queue ->
        # %2F is for '/'
        api = api <> "/queues/%2F/#{obj}"
        {:ok, result} = get(api)

        case result.status_code do
          200 ->
            {:ok, result.body}

          404 ->
            {:error, "not found"}

          _ ->
            {:error, "unknow"}
        end
    end
  end

  defp do_delete(api, type, obj) do
    case type do
      :exchange ->
        api = api <> "/exchanges/%2F/#{obj}/bindings/source"
        {:ok, bindings} = get(api)

        Enum.each(bindings.body, fn binding ->
          # delete queue
          api = api <> "/queues/%2F/#{binding["destination"]}"
          delete!(api)
        end)

        # delete exchange
        api = api <> "/exchanges/%2F/#{obj}"
        delete!(api)
        {:ok}

      :queue ->
        api = api <> "/queues/%2F/#{obj}"
        delete!(api)
        {:ok}
    end
  end
end
