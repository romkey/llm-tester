# frozen_string_literal: true

require "test_helper"

class FormsHelperTest < ActionView::TestCase
  include FormsHelper

  setup do
    @server = servers(:ollama)
    @form = ActionView::Helpers::FormBuilder.new(
      :server,
      @server,
      ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil),
      {}
    )
  end

  test "field_requirement_badge renders required" do
    assert_includes field_requirement_badge(required: true), "Required"
  end

  test "field_requirement_badge renders optional" do
    assert_includes field_requirement_badge(optional: true), "Optional"
  end

  test "form_label_with_requirement includes badge and hint" do
    html = form_label_with_requirement(@form, :api_key, text: "API Key", optional: true, hint: "Only if needed.")

    assert_includes html, "API Key"
    assert_includes html, "Optional"
    assert_includes html, "Only if needed."
  end
end
