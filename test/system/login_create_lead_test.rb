# frozen_string_literal: true

require "application_system_test_case"

class LoginCreateLeadTest < ApplicationSystemTestCase
  test "login then create lead shows on detail page" do
    visit login_path

    fill_in "email", with: users(:advisor).email
    fill_in "password", with: "password"
    click_button "Sign in"

    assert_text "Signed in successfully."

    visit new_lead_path
    assert_text "New lead"
    assert_selector "form"

    email = "system.test.lead.#{SecureRandom.hex(4)}@example.com"

    fill_in "name", with: "System Test Lead"
    fill_in "email", with: email
    fill_in "company_name", with: "System Test Co"
    # React controlled <select>s: Capybara's select() updates the DOM but may not
    # fire React onChange; set value + dispatch events so Inertia setData runs.
    select_react "company_country_id", countries(:us).id
    select_react "country_id", countries(:us).id
    select_react "stage_id", lead_stages(:prospect).id

    click_button "Create lead"

    assert_text "Lead created.", wait: 10
    assert_text "System Test Lead"
    assert_current_path %r{/leads/\d+}
  end

  private

  def select_react(element_id, value)
    find("##{element_id}", visible: true)

    page.execute_script(<<~JS, element_id, value.to_s)
      const el = document.getElementById(arguments[0]);
      const setter = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, "value").set;
      setter.call(el, arguments[1]);
      el.dispatchEvent(new Event("input", { bubbles: true }));
      el.dispatchEvent(new Event("change", { bubbles: true }));
    JS

    assert_equal value.to_s, find("##{element_id}").value
  end
end
