# frozen_string_literal: true

require "test_helper"

class FooterTest < ActionDispatch::IntegrationTest
  test "footer shows version and github link" do
    get root_url
    assert_response :success
    assert_select "footer", /Version #{Regexp.escape(AppVersion.current)}/
    assert_select "footer a[href=?]", AppVersion.github_repo_url, text: AppVersion.github_repo_label
  end
end
