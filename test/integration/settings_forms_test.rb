# frozen_string_literal: true

require "test_helper"

class SettingsFormsTest < ActionDispatch::IntegrationTest
  test "server form marks required and optional fields" do
    get edit_settings_server_url(servers(:ollama))
    assert_response :success
    assert_select "label", /Name.*Required/m
    assert_select "label", /IP \/ Hostname.*Required/m
    assert_select "label", /API Key.*Optional/m
  end

  test "model form marks required and optional fields" do
    get edit_settings_llm_model_url(llm_models(:llama))
    assert_response :success
    assert_select "label", /Name.*Required/m
    assert_select "label", /Server.*Required/m
    assert_select "label", /Enabled.*Optional/m
  end

  test "test definition form marks required and optional fields" do
    get edit_settings_test_definition_url(test_definitions(:exact_greeting))
    assert_response :success
    assert_select "label", /Name.*Required/m
    assert_select "label", /Run on all models.*Optional/m
    assert_select "label", /Expected Response.*Optional/m
    assert_select "label", /Regex Pattern.*Optional/m
    assert_select "label", /Enabled.*Optional/m
  end
end
