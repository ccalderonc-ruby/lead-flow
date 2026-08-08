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
    company_country_id = countries(:us).id.to_s
    country_id = countries(:us).id.to_s
    stage_id = lead_stages(:prospect).id.to_s

    fill_in "name", with: "System Test Lead"
    fill_in "email", with: email
    fill_in "company_name", with: "System Test Co"

    # Set selects immediately before submit. React controlled selects can reset
    # between an earlier set and the click; lead create also syncs DOM → payload.
    page.execute_script(<<~JS, company_country_id, country_id, stage_id)
      const setSelect = (id, value) => {
        const el = document.getElementById(id);
        const setter = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, "value").set;
        const tracker = el._valueTracker;
        if (tracker) tracker.setValue("");
        setter.call(el, value);
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      };
      setSelect("company_country_id", arguments[0]);
      setSelect("country_id", arguments[1]);
      setSelect("stage_id", arguments[2]);
      const form = document.querySelector("form");
      form.noValidate = true;
      form.requestSubmit();
    JS

    assert_text "Lead created.", wait: 10
    assert_text "System Test Lead"
    assert_current_path %r{/leads/\d+}
  end
end
