# frozen_string_literal: true

require "test_helper"

class LeadPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @advisor = users(:advisor)
    @assistant = users(:assistant)
    @advisor_lead = leads(:sarah)
    @other_lead = leads(:admin_owned)
  end

  test "admin can update any lead" do
    assert LeadPolicy.new(@admin, @other_lead).update?
  end

  test "advisor can update assigned lead" do
    assert LeadPolicy.new(@advisor, @advisor_lead).update?
  end

  test "advisor cannot update lead assigned to another user" do
    refute LeadPolicy.new(@advisor, @other_lead).update?
  end

  test "assistant cannot destroy lead" do
    refute LeadPolicy.new(@assistant, @advisor_lead).destroy?
  end

  test "assistant can show lead owned by assigned advisor" do
    assert LeadPolicy.new(@assistant, @advisor_lead).show?
  end

  test "assistant cannot show lead owned by unassigned advisor" do
    refute LeadPolicy.new(@assistant, @other_lead).show?
  end

  test "assistant scope is limited to assigned advisors" do
    scoped = LeadPolicy::Scope.new(@assistant, Lead).resolve

    assert_includes scoped, @advisor_lead
    refute_includes scoped, @other_lead
  end

  test "unassigned assistant scope is empty" do
    AdvisorAssistant.delete_all

    assert_empty LeadPolicy::Scope.new(@assistant, Lead).resolve
  end

  test "admin and advisor can create leads" do
    assert LeadPolicy.new(@admin, Lead).create?
    assert LeadPolicy.new(@advisor, Lead).create?
  end

  test "assistant cannot create leads" do
    refute LeadPolicy.new(@assistant, Lead).create?
  end

  test "assistant cannot update leads" do
    refute LeadPolicy.new(@assistant, @advisor_lead).update?
  end

  test "subscribed advisor can export when org billing is active" do
    users(:billing_admin).update!(subscription_status: "active")
    assert LeadPolicy.new(users(:advisor_subscribed), Lead).export?
  end

  test "inactive advisor cannot export" do
    users(:billing_admin).update!(subscription_status: "active")
    refute LeadPolicy.new(@advisor, Lead).export?
  end

  test "billing admin can export without advisor role when subscribed" do
    billing_admin = users(:billing_admin)
    refute LeadPolicy.new(billing_admin, Lead).export?

    billing_admin.update!(subscription_status: "active")
    assert LeadPolicy.new(billing_admin, Lead).export?
  end

  test "regular admin can export when granted pro access" do
    users(:billing_admin).update!(subscription_status: "active")
    refute LeadPolicy.new(@admin, Lead).export?

    @admin.update!(pro_access: true)
    assert LeadPolicy.new(@admin, Lead).export?
  end

  test "assistant cannot export" do
    users(:billing_admin).update!(subscription_status: "active")
    users(:assistant).update!(pro_access: true)
    refute LeadPolicy.new(@assistant, Lead).export?
  end
end
