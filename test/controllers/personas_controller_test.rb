require 'test_helper'

class PersonasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @persona = personas(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get personas_url
    assert_response :success
  end

  test 'should get show' do
    get persona_url(@persona)
    assert_response :success
  end

  test 'should get new' do
    get new_persona_url
    assert_response :success
  end

  test 'should get edit' do
    get edit_persona_url(@persona)
    assert_response :success
  end

  test 'should create persona' do
    assert_difference('Persona.count') do
      post personas_url, params: {
        persona: {
          name: 'Test Persona',
          description: 'Test description',
          base_prompt: 'Test prompt'
        }
      }
    end
    assert_redirected_to persona_url(Persona.last)
  end

  test 'should update persona' do
    patch persona_url(@persona), params: {
      persona: {
        name: 'Updated Name',
        description: @persona.description,
        base_prompt: @persona.base_prompt
      }
    }
    assert_redirected_to persona_url(@persona)
  end

  test 'should destroy persona' do
    assert_difference('Persona.count', -1) do
      delete persona_url(@persona)
    end
    assert_redirected_to personas_url
  end
end
