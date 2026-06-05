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

  test "layouts do not use invalid data-bs-theme auto value" do
    [ root_url, settings_root_url ].each do |url|
      get url
      assert_response :success
      assert_select "html[data-bs-theme=auto]", 0
    end
  end

  test "bootstrap scss enables media-query color mode before import" do
    source = Rails.root.join("app/assets/stylesheets/application.bootstrap.scss").read
    assert_match(/\$color-mode-type:\s*media-query;/, source)
    assert_operator source.index("$color-mode-type"), :<, source.index("@import 'bootstrap")
  end

  test "compiled stylesheet follows system prefers-color-scheme" do
    css = Rails.root.join("app/assets/builds/application.css").read
    assert_includes css, "prefers-color-scheme: dark"
  end
end
