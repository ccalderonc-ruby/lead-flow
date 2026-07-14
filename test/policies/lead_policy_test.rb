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

  test "assistant can show any lead" do
    assert LeadPolicy.new(@assistant, @other_lead).show?
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
end
