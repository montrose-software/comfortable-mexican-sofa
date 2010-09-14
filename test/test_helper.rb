ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all
  include ActionDispatch::TestProcess
  
  # Example usage:
  #   assert_has_errors_on( @record, [:field_1, :field_2] )
  #   assert_has_errors_on( @record, {:field_1 => 'Message1', :field_2 => 'Message 2'} )
  def assert_has_errors_on(record, fields)
    fields = [fields].flatten unless fields.is_a?(Hash)
    fields.each do |field, message|
      assert record.errors.has_key?(field.to_sym), "#{record.class.name} should error on invalid #{field}"
      if message && record.errors[field].is_a?(Array) && !message.is_a?(Array)
        assert_not_nil record.errors[field].index(message)
      elsif message
        assert_equal message, record.errors[field]
      end
    end
  end
end

class ActionController::TestCase
  
  def http_auth
    @request.env['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('username:password')}"
  end
  
end