# frozen_string_literal: true

require "base64"

module Inference
  class ImageEncoder
    EncodedImage = Data.define(:base64, :content_type)

    def self.from_attachment(attachment)
      return [] unless attachment.attached?

      blob = attachment.blob
      [ EncodedImage.new(
        base64: Base64.strict_encode64(blob.download),
        content_type: blob.content_type
      ) ]
    end
  end
end
