require 'test_helper'
require 'site_org_seeds_test_helper'
require 'user_seeds_test_helper'

class HeadcountsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @org = SiteOrgSeedsTestHelper.seed_org
    @site = SiteOrgSeedsTestHelper.seed_site(@org)
    @room = Room.create({
      site: @site,
      capacity: 100
    })
    @validUser = UserSeedsTestHelper.seed_user
    @validUser = Role.grant_user_role(@validUser, :site_employee, @site)
    @invalidUser = UserSeedsTestHelper.seed_user
    @invalidUser = Role.grant_user_role(@invalidUser, :global_dataviewer)
    
    @headcount_create_params = {
      room_id: @room.id,
      occupancy: 50,
      recorded_by: @validUser,
      recorded_at: Time.now
    }

    @headcount = Headcount.create!(@headcount_create_params)

    # an old headcount
    old_time = Time.now - (Rails.application.config.headcount_edit_window_minutes + 1).minutes
    @old_headcount = Headcount.create!(@headcount_create_params.merge({ recorded_at: old_time}))
  end

  test "should get index" do
    get headcounts_url, as: :json
    assert_response :success
  end

  test "should create headcount" do
    sign_in @validUser
    assert_difference 'Headcount.count' do
      post headcounts_url, params: { headcount: @headcount_create_params }, as: :json
    end

    assert_response 201
  end

  test "shouldn't create headcount with bad room" do
    sign_in @validUser
    bad_room_params = {
      room_id: 999999999,
      occupancy: 50
    }

    post headcounts_url, params: { headcount: bad_room_params }, as: :json
    assert_response 400
  end

  test "shouldn't create headcount if signed out" do
    post headcounts_url, params: { headcount: @headcount_create_params }, as: :json
    assert_response 403
  end

  test "shouldn't create headcount if unauthorized user" do
    sign_in @invalidUser
    post headcounts_url, params: { headcount: @headcount_create_params }, as: :json
    assert_response 403
  end

  test "should show headcount" do
    get headcount_url(@headcount), as: :json
    assert_response :success
  end

  test "should update recently changed headcount" do
    sign_in @validUser
    patch headcount_url(@headcount), params: { headcount: { occupancy: 10  } }, as: :json
    assert_response 200
  end

  test "should not update old headcount" do
    sign_in @validUser
    patch headcount_url(@old_headcount), params: { headcount: { occupancy: 20  } }, as: :json
    assert_response 400
  end

  test "should not update headcount if signed out" do
    patch headcount_url(@headcount), params: { headcount: { occupancy: 20  } }, as: :json
    assert_response 403
  end

  test "should not update headcount if unauthorized user" do
    sign_in @invalidUser
    patch headcount_url(@headcount), params: { headcount: { occupancy: 20  } }, as: :json
    assert_response 403
  end

  # test "should destroy headcount" do
  #   assert_difference('Headcount.count', -1) do
  #     delete headcount_url(@headcount), as: :json
  #   end

  #   assert_response 204
  # end
end
