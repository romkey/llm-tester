# frozen_string_literal: true

module NavbarHelper
  def nav_link_class(path)
    base = "nav-link"
    current_page?(path) ? "#{base} active" : base
  end
end
