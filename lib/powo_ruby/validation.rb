# frozen_string_literal: true

module PowoRuby
  # Tiny validation helpers used by the public API.
  #
  # These are intentionally small and strict: they fail fast with {PowoRuby::ValidationError}
  # to keep endpoint methods predictable for callers.
  module Validation
    module_function

    # Validate that a value is present.
    #
    # @param value [Object]
    # @param name [String] parameter name for error messages
    # @return [void]
    def presence!(value, name:)
      return unless value.nil? || value.to_s.strip.empty?

      raise ValidationError, "#{name} must be provided"
    end

    # Validate that a value is a Hash.
    #
    # @param value [Object]
    # @param name [String]
    # @return [void]
    def hash!(value, name:)
      return if value.is_a?(Hash)

      raise ValidationError, "#{name} must be a Hash"
    end

    # Validate that a value is boolean (true/false).
    #
    # @param value [Object]
    # @param name [String]
    # @return [void]
    def boolean!(value, name:)
      return if [true, false].include?(value)

      raise ValidationError, "#{name} must be boolean (true/false)"
    end
  end
end
