# frozen_string_literal: true

require "test_helper"

class DarkModeLayoutTest < ActionDispatch::IntegrationTest
  test "layout advertises light and dark color schemes" do
    get root_url
    assert_response :success
    assert_select "meta[name='color-scheme'][content='light dark']"
  end

  test "settings layout advertises light and dark color schemes" do
    get settings_root_url
    assert_response :success
    assert_select "meta[name='color-scheme'][content='light dark']"
  end

  test "compiled stylesheet follows system prefers-color-scheme" do
    css = Rails.root.join("app/assets/builds/application.css").read
    assert_includes css, "prefers-color-scheme: dark"
  end
end
