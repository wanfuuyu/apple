defmodule Apple.UI.Navigate do
  use Kino.JS

  def header(elems) do
    Kino.Markdown.new("""
    <div style="display: flex; align-items: center; width: 100%; justify-content: space-between; font-size: 1rem; color: #61758a; background-color: #f0f5f9; height: 4rem; padding: 0 1rem; border-radius: 1rem;">
    <div style="display: flex;">
    <i class="ri-home-fill"></i>
    <a style="display: flex; color: #61758a; margin-left: 1rem;" href="../homepage.livemd">Home</a>
    </div>
    """)
  end

  def next(label, file) do
    Kino.Markdown.new("""
    <div style="display: flex; justify-content: flex-end;">
    <a style="display: flex; color: #61758a; " href="#{file}">#{label}</a>
    <i class="ri-arrow-right-line"></i>
    </div>
    """)
  end

  def prev(label, file) do
    Kino.Markdown.new("""
    <div style="display: flex; justify-content: flex-start;">
    <i class="ri-arrow-left-line"></i>
    <a style="display: flex; color: #61758a; " href="#{file}">#{label}</a>
    </div>
    """)
  end
end
