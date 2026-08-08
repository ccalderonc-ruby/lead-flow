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

    # Set controlled React fields + submit in one browser script so CI Chrome
    # does not lose values between Capybara fill_in and the Inertia POST.
    page.execute_script(<<~JS, email, countries(:us).id.to_s, lead_stages(:prospect).id.to_s)
      const setField = (id, value) => {
        const el = document.getElementById(id);
        const proto = el.tagName === "SELECT" ? window.HTMLSelectElement.prototype : window.HTMLInputElement.prototype;
        const setter = Object.getOwnPropertyDescriptor(proto, "value").set;
        const tracker = el._valueTracker;
        if (tracker) tracker.setValue("");
        setter.call(el, value);
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      };

      setField("name", "System Test Lead");
      setField("email", arguments[0]);
      setField("company_name", "System Test Co");
      setField("company_country_id", arguments[1]);
      setField("country_id", arguments[1]);
      setField("stage_id", arguments[2]);

      const form = document.querySelector("form");
      form.noValidate = true;
      form.requestSubmit();
    JS

    assert_text "Lead created.", wait: 10
    assert_text "System Test Lead"
    assert_current_path %r{/leads/\d+}
  end
end
