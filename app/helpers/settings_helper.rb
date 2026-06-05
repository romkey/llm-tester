# frozen_string_literal: true

module SettingsHelper
  def settings_nav_class(path)
    base = "list-group-item list-group-item-action"
    current_page?(path) ? "#{base} active" : base
  end
end
