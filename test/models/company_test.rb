require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert companies(:acme).valid?
  end

  test "requires name and country" do
    company = Company.new(country: countries(:us))
    assert_not company.valid?
    assert_includes company.errors[:name], "can't be blank"
  end

  test "normalize_name strips suffixes and punctuation" do
    assert_equal "acme", Company.normalize_name("Acme Corp.")
    assert_equal "technova solutions", Company.normalize_name("TechNova Solutions, LLC")
  end

  test "sets normalized_name before validation" do
    company = Company.create!(name: "Global Industries Inc.", country: countries(:cr))
    assert_equal "global industries", company.normalized_name
  end

  test "find_or_initialize_by_name finds existing company" do
    existing = companies(:acme)
    result = Company.find_or_initialize_by_name("ACME Corp")
    assert_equal existing, result
    assert_not result.new_record?
  end

  test "find_or_initialize_by_name initializes new company when not found" do
    result = Company.find_or_initialize_by_name("New Startup LLC")
    assert result.new_record?
    assert_equal "New Startup LLC", result.name
    assert_equal "new startup", result.normalized_name
  end

  test "normalized_name must be unique" do
    duplicate = Company.new(name: "ACME Corporation", country: countries(:us))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized_name], "has already been taken"
  end
end
