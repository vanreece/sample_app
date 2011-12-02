require 'spec_helper'

describe User do
  context "validations" do
    before do
      @attrs = { name: "Christian", email: "christian@example.com" }
    end
    
    it "should actually write a valid user" do
      User.create!(@attrs)
    end

    it "should require a name" do
      user = User.new(@attrs.delete(:name))
      user.should_not be_valid
      user.errors.should include :name
    end

    it "should require an email" do
      user = User.new(@attrs.delete(:email))
      user.should_not be_valid
      user.errors.should include :email
    end

    it "should reject names that are too long" do
      long_name = "a" * 51
      user = User.new(@attrs.merge(name: long_name))
      user.should_not be_valid
      user.errors.should include :name
    end

    it "should accept valid email addresses" do
      addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
      addresses.each do |address|
        valid_email_user = User.new(@attrs.merge(:email => address))
        valid_email_user.should be_valid
      end
    end

    it "should reject invalid email addresses" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
      addresses.each do |address|
        invalid_email_user = User.new(@attrs.merge(:email => address))
        invalid_email_user.should_not be_valid
      end
    end

    it "should reject duplicate email addresses" do
      # Put a user with given email address into the database.
      User.create!(@attrs)
      user_with_duplicate_email = User.new(@attrs)
      user_with_duplicate_email.should_not be_valid
      user_with_duplicate_email.errors.should include :email
    end
  end
end
