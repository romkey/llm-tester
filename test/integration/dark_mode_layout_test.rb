# frozen_string_literal: true

require "test_helper"

class DarkModeLayoutTest < ActionDispatch::IntegrationTest
  test "layout follows system color scheme" do
    get root_url
    assert_response :success
    assert_select "html[data-bs-theme='auto']"
    assert_select "meta[name='color-scheme'][content='light dark']"
  end

  test "settings layout follows system color scheme" do
    get settings_root_url
    assert_response :success
    assert_select "html[data-bs-theme='auto']"
  end
end
