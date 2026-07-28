# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Match routes.rb redirect from 127.0.0.1 → localhost (Vite cookie host).
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    Capybara.server_host = "localhost"
    Capybara.app_host = "http://localhost"
  end
end
