require 'test_helper'

class HeatmapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @heatmap = heatmaps(:one)
  end

  test "should get index" do
    get heatmaps_url
    assert_response :success
  end

  test "should get new" do
    get new_heatmap_url
    assert_response :success
  end

  test "should create heatmap" do
    assert_difference('Heatmap.count') do
      post heatmaps_url, params: { heatmap: {  } }
    end

    assert_redirected_to heatmap_url(Heatmap.last)
  end

  test "should show heatmap" do
    get heatmap_url(@heatmap)
    assert_response :success
  end

  test "should get edit" do
    get edit_heatmap_url(@heatmap)
    assert_response :success
  end

  test "should update heatmap" do
    patch heatmap_url(@heatmap), params: { heatmap: {  } }
    assert_redirected_to heatmap_url(@heatmap)
  end

  test "should destroy heatmap" do
    assert_difference('Heatmap.count', -1) do
      delete heatmap_url(@heatmap)
    end

    assert_redirected_to heatmaps_url
  end
end
