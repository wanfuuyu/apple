defmodule Apple.UI.Callout do
  use Kino.JS

  @style """
  <!DOCTYPE html>
  <html>
  <head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
  div {
  margin-bottom: 15px;
  padding: 4px 12px;
  }

  .danger {
  background-color: #ffdddd;
  border-left: 6px solid #f44336;
  }

  .success {
  background-color: #ddffdd;
  border-left: 6px solid #04AA6D;
  }

  .info {
  background-color: #e7f3fe;
  border-left: 6px solid #2196F3;
  }

  .warning {
  background-color: #ffffcc;
  border-left: 6px solid #ffeb3b;
  }

  </style>
  </head>
  <body>


  """

  defp output(content) when is_binary(content) do
    Kino.JS.new(__MODULE__, @style <> content)
  end

  def info(content) do
    new(:info, content)
  end

  def danger(content) do
    new(:danger, content)
  end

  def success(content) do
    new(:success, content)
  end

  def warning(content) do
    new(:warning, content)
  end

  defp new(type, content) when is_binary(content) do
    case type do
      :info ->
        """
        <div class="info">
        <p><strong>INFO!</strong> #{content}</p>
        </div>
        """
        |> output()

      :danger ->
        """
        <div class="danger">
        <p><strong>DANGER!</strong> #{content}</p>
        </div>
        """
        |> output()

      :warning ->
        """
        <div class="warning">
        <p><strong>WARNING!</strong> #{content}</p>
        </div>
        """
        |> output()

      :success ->
        """
        <div class="success">
        <p><strong>SUCCESS!</strong> #{content}</p>
        </div>
        """
        |> output()
    end
  end

  asset "main.js" do
    """
    export function init(ctx, html) {
      ctx.root.innerHTML = html;
    }
    """
  end
end
