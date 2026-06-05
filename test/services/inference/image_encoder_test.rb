# frozen_string_literal: true

require "test_helper"

class InferenceImageEncoderTest < ActiveSupport::TestCase
  test "returns empty array when no attachment" do
    definition = test_definitions(:exact_greeting)
    assert_empty Inference::ImageEncoder.from_attachment(definition.image)
  end

  test "encodes attached image as base64 with content type" do
    definition = test_definitions(:exact_greeting)
    definition.image.attach(
      io: File.open(file_fixture("sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    encoded = Inference::ImageEncoder.from_attachment(definition.image)
    assert_equal 1, encoded.length
    assert_equal "image/png", encoded.first.content_type
    assert_equal Base64.strict_encode64(file_fixture("sample.png").read), encoded.first.base64
  end
end
