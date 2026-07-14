require "test_helper"

class LeadTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert leads(:sarah).valid?
  end

  test "requires name, country, company, and email" do
    lead = Lead.new(
      user: users(:advisor),
      stage: lead_stages(:prospect)
    )
    assert_not lead.valid?
    assert_includes lead.errors[:name], "can't be blank"
    assert_includes lead.errors[:country], "must exist"
    assert_includes lead.errors[:company], "must exist"
    assert_includes lead.errors[:email], "can't be blank"
  end

  test "associates with opportunities, tasks, notes, and tags" do
    lead = leads(:sarah)
    assert_includes lead.opportunities, opportunities(:migration)
    assert_includes lead.tasks, tasks(:follow_up)
    assert_includes lead.notes, notes(:discovery)
    assert_includes lead.tags, tags(:priority)
  end

  test "rejects duplicate email case-insensitively" do
    duplicate = Lead.new(
      name: "Another Sarah",
      email: "SARAH@EXAMPLE.COM",
      user: users(:advisor),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "already belongs to another lead"
  end

  test "normalizes email before save" do
    lead = Lead.create!(
      name: "Norm Case",
      email: "  Norm@Example.COM ",
      user: users(:advisor),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert_equal "norm@example.com", lead.reload.email
  end

  test "find_or_initialize_by_email reuses an existing lead" do
    existing = leads(:sarah)
    lead = Lead.find_or_initialize_by_email(
      "Sarah@Example.com",
      name: "Should not create",
      user: users(:advisor),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert_equal existing.id, lead.id
    assert lead.persisted?
  end

  test "find_or_initialize_by_email builds a new lead when email is unused" do
    lead = Lead.find_or_initialize_by_email(
      "new.prospect@example.com",
      name: "New Prospect",
      user: users(:advisor),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert lead.new_record?
    assert_equal "new.prospect@example.com", lead.email
    assert_equal "New Prospect", lead.name
  end

  test "blank emails are rejected" do
    lead = Lead.new(
      name: "No Email",
      email: "   ",
      user: users(:advisor),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert_not lead.valid?
    assert_includes lead.errors[:email], "can't be blank"
  end

  test "updating email to a duplicate is rejected" do
    lead = leads(:marcus)
    lead.email = "SARAH@EXAMPLE.COM"

    assert_not lead.valid?
    assert_includes lead.errors[:email], "already belongs to another lead"
  end

  test "find_or_initialize_by_email does not overwrite existing attributes" do
    existing = leads(:sarah)
    original_name = existing.name

    lead = Lead.find_or_initialize_by_email(
      existing.email,
      name: "Hijacked Name",
      user: users(:admin),
      stage: lead_stages(:prospect),
      company: companies(:acme),
      country: countries(:us)
    )

    assert_equal existing.id, lead.id
    assert_equal original_name, lead.name
    assert_equal existing.user_id, lead.user_id
  end
end
