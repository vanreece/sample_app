require 'spec_helper'

describe User do
  before do
    @attr = {
        name: "Christian",
        email: "christian@example.com",
        password: "foobar",
        password_confirmation: "foobar"
    }
  end

  describe "validations" do

    it "should actually write a valid user" do
      User.create!(@attr)
    end

    describe "name" do
      it "should be required" do
        user = User.new(@attr.delete(:name))
        user.should_not be_valid
        user.errors.should include :name
      end

      it "should reject long values" do
        long_name = "a" * 51
        user = User.new(@attr.merge(name: long_name))
        user.should_not be_valid
        user.errors.should include :name
      end
    end

    describe "email" do
      it "should be required" do
        user = User.new(@attr.delete(:email))
        user.should_not be_valid
        user.errors.should include :email
      end

      it "should accept valid values" do
        addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
        addresses.each do |address|
          valid_email_user = User.new(@attr.merge(:email => address))
          valid_email_user.should be_valid
        end
      end

      it "should reject invalid values" do
        addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
        addresses.each do |address|
          invalid_email_user = User.new(@attr.merge(:email => address))
          invalid_email_user.should_not be_valid
        end
      end

      it "should reject duplicates" do
        # Put a user with given email address into the database.
        User.create!(@attr)
        user_with_duplicate_email = User.new(@attr)
        user_with_duplicate_email.should_not be_valid
        user_with_duplicate_email.errors.should include :email
      end
    end

    describe "password" do
      it "should be required" do
        user = User.new(@attr.merge(:password => "", :password_confirmation => ""))
        user.should_not be_valid
        user.errors.should include :password
      end

      it "should match confirmation" do
        user = User.new(@attr.merge(:password_confirmation => "invalid"))
        user.should_not be_valid
        user.errors.should include :password
      end

      it "should reject short values" do
        short = "a" * 5
        hash = @attr.merge(:password => short, :password_confirmation => short)
        user = User.new(hash)
        user.should_not be_valid
        user.errors.should include :password
      end

      it "should reject long values" do
        long = "a" * 41
        hash = @attr.merge(:password => long, :password_confirmation => long)
        user = User.new(hash)
        user.should_not be_valid
        user.errors.should include :password
      end

      describe "encryption" do
        before(:each) do
          @user = User.create!(@attr)
        end

        it "should have an encrypted password attribute" do
          @user.should respond_to(:encrypted_password)
        end

        it "should set the encrypted password" do
          @user.encrypted_password.should_not be_blank
        end

        describe "has_password? method" do
          it "should be true if the passwords match" do
            @user.has_password?(@attr[:password]).should be_true
          end

          it "should be false if the passwords don't match" do
            @user.has_password?("invalid").should be_false
          end
        end
      end
    end
  end

  describe "#authenticate" do
    it "should return nil on email/password mismatch" do
      wrong_password_user = User.authenticate(@attr[:email], "wrongpass")
      wrong_password_user.should be_nil
    end

    it "should return nil for an email address with no user" do
      nonexistent_user = User.authenticate("bar@foo.com", @attr[:password])
      nonexistent_user.should be_nil
    end

    it "should return the user on email/password match" do
      user = User.create!(@attr)
      matching_user = User.authenticate(@attr[:email], @attr[:password])
      matching_user.should == user
    end
  end

  describe "admin attribute" do
    before(:each) do
      @user = User.create!(@attr)
    end

    it "should respond to admin" do
      @user.should respond_to(:admin)
    end

    it "should not be an admin by default" do
      @user.should_not be_admin
    end

    it "should be convertible to an admin" do
      @user.toggle!(:admin)
      @user.should be_admin
    end
  end

  describe "micropost associations" do
    before(:each) do
      @user = User.create(@attr)
      @mp1 = Factory(:micropost, :user => @user, :created_at => 1.day.ago)
      @mp2 = Factory(:micropost, :user => @user, :created_at => 1.hour.ago)
    end

    it "should have a microposts attribute" do
      @user.should respond_to(:microposts)
    end

    it "should have the right microposts in the right order" do
      @user.microposts.should == [@mp2, @mp1]
    end

    it "should destroy associated microposts" do
      @user.destroy
      [@mp1, @mp2].each do |micropost|
        Micropost.find_by_id(micropost.id).should be_nil
      end
    end

    describe "status feed" do
      it "should have a feed" do
        @user.should respond_to(:feed)
      end

      it "should include the user's microposts" do
        @user.feed.should include(@mp1)
        @user.feed.should include(@mp2)
      end

      it "should not include a different user's microposts" do
        mp3 = Factory(:micropost,
                      :user => Factory(:user, :email => Factory.next(:email)))
        @user.feed.should_not include(mp3)
      end

      it "should include the microposts of followed users" do
        followed = Factory(:user, :email => Factory.next(:email))
        mp3 = Factory(:micropost, :user => followed)
        @user.follow!(followed)
        @user.feed.should include(mp3)
      end
    end
  end

  describe "relationships" do
    before(:each) do
      @user = User.create!(@attr)
      @followed = Factory(:user)
    end

    it "should have a relationships method" do
      @user.should respond_to(:relationships)
    end

    it "should have a following method" do
      @user.should respond_to(:following)
    end

    it "should have a following? method" do
      @user.should respond_to(:following?)
    end

    it "should have a follow! method" do
      @user.should respond_to(:follow!)
    end

    it "should follow another user" do
      @user.follow!(@followed)
      @user.should be_following(@followed)
    end

    it "should include the followed user in the following array" do
      @user.follow!(@followed)
      @user.following.should include(@followed)
    end

    it "should have an unfollow! method" do
      @followed.should respond_to(:unfollow!)
    end

    it "should unfollow a user" do
      @user.follow!(@followed)
      @user.unfollow!(@followed)
      @user.should_not be_following(@followed)
    end

    it "should have a reverse_relationships method" do
      @user.should respond_to(:reverse_relationships)
    end

    it "should have a followers method" do
      @user.should respond_to(:followers)
    end

    it "should include the follower in the followers array" do
      @user.follow!(@followed)
      @followed.followers.should include(@user)
    end
  end
end
