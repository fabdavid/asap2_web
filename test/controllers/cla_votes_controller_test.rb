require 'test_helper'

class ClaVotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cla_vote = cla_votes(:one)
  end

  test "should get index" do
    get cla_votes_url
    assert_response :success
  end

  test "should get new" do
    get new_cla_vote_url
    assert_response :success
  end

  test "should create cla_vote" do
    assert_difference('ClaVote.count') do
      post cla_votes_url, params: { cla_vote: {  } }
    end

    assert_redirected_to cla_vote_url(ClaVote.last)
  end

  test "should show cla_vote" do
    get cla_vote_url(@cla_vote)
    assert_response :success
  end

  test "should get edit" do
    get edit_cla_vote_url(@cla_vote)
    assert_response :success
  end

  test "should update cla_vote" do
    patch cla_vote_url(@cla_vote), params: { cla_vote: {  } }
    assert_redirected_to cla_vote_url(@cla_vote)
  end

  test "should destroy cla_vote" do
    assert_difference('ClaVote.count', -1) do
      delete cla_vote_url(@cla_vote)
    end

    assert_redirected_to cla_votes_url
  end
end
