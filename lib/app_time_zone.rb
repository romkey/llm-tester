# frozen_string_literal: true

# Resolves a TZ-style identifier (e.g. "America/Los_Angeles") into an
# ActiveSupport::TimeZone name, or nil when the value is blank or unrecognized.
# Lives in lib and is required directly from config/application.rb because the
# display time zone must be configured during boot, before autoloading.
module AppTimeZone
  module_function

  def resolve(identifier)
    return if identifier.blank?

    ActiveSupport::TimeZone[identifier]&.name
  end
end
