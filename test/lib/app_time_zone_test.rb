# frozen_string_literal: true

require "test_helper"

class AppTimeZoneTest < ActiveSupport::TestCase
  test "resolves a TZ identifier to a zone name" do
    assert_equal "America/Los_Angeles", AppTimeZone.resolve("America/Los_Angeles")
  end

  test "resolves a friendly zone name" do
    assert_equal "Central Time (US & Canada)", AppTimeZone.resolve("Central Time (US & Canada)")
  end

  test "returns nil for blank input" do
    assert_nil AppTimeZone.resolve(nil)
    assert_nil AppTimeZone.resolve("")
  end

  test "returns nil for an unrecognized zone" do
    assert_nil AppTimeZone.resolve("Not/AZone")
  end
end
