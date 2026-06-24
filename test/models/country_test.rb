require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert countries(:us).valid?
  end

  test "requires name and iso_code" do
    country = Country.new(iso_code: "MX")
    assert_not country.valid?
    assert_includes country.errors[:name], "can't be blank"

    country = Country.new(name: "Mexico")
    assert_not country.valid?
    assert_includes country.errors[:iso_code], "can't be blank"
  end

  test "iso_code must be exactly two characters" do
    country = countries(:us).dup
    country.iso_code = "USA"
    assert_not country.valid?
    assert_includes country.errors[:iso_code], "is the wrong length (should be 2 characters)"
  end

  test "name and iso_code must be unique" do
    duplicate = Country.new(name: countries(:us).name, iso_code: "MX")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    duplicate = Country.new(name: "Duplicate", iso_code: countries(:us).iso_code)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:iso_code], "has already been taken"
  end
end
