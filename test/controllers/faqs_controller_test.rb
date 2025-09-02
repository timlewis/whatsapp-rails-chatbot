require 'test_helper'

class FaqsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faq = faqs(:one)
    @admin_user = admin_users(:one)
    sign_in_as(@admin_user)
  end

  test 'should get index' do
    get faqs_url
    assert_response :success
  end

  test 'should get show' do
    get faq_url(@faq)
    assert_response :success
  end

  test 'should get new' do
    get new_faq_url
    assert_response :success
  end

  test 'should get edit' do
    get edit_faq_url(@faq)
    assert_response :success
  end

  test 'should create faq' do
    assert_difference('Faq.count') do
      post faqs_url, params: {
        faq: {
          question: 'How do I use this feature?',
          answer: 'You can use this feature by following these steps...',
          active: true
        }
      }
    end

    assert_redirected_to faq_url(Faq.last)
    assert_equal 'FAQ was successfully created.', flash[:notice]
  end

  test 'should update faq' do
    patch faq_url(@faq), params: {
      faq: {
        question: 'Updated question?',
        answer: 'Updated answer',
        active: false
      }
    }
    assert_redirected_to faq_url(@faq)
    assert_equal 'FAQ was successfully updated.', flash[:notice]

    @faq.reload
    assert_equal 'Updated question?', @faq.question
    assert_equal 'Updated answer', @faq.answer
    assert_not @faq.active
  end

  test 'should destroy faq' do
    assert_difference('Faq.count', -1) do
      delete faq_url(@faq)
    end

    assert_redirected_to faqs_url
    assert_equal 'FAQ was successfully deleted.', flash[:notice]
  end

  test 'should not create invalid faq' do
    assert_no_difference('Faq.count') do
      post faqs_url, params: {
        faq: {
          question: '',
          answer: '',
          active: true
        }
      }
    end

    assert_response :unprocessable_content
  end
end
