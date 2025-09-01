require 'test_helper'

class FaqTest < ActiveSupport::TestCase
  test 'should validate presence of question' do
    faq = Faq.new(answer: 'Valid answer')
    assert_not faq.valid?
    assert_includes faq.errors[:question], "can't be blank"
  end

  test 'should validate presence of answer' do
    faq = Faq.new(question: 'Valid question?')
    assert_not faq.valid?
    assert_includes faq.errors[:answer], "can't be blank"
  end

  test 'should validate minimum length of question' do
    faq = Faq.new(question: 'Short', answer: 'Valid answer')
    assert_not faq.valid?
    assert_includes faq.errors[:question], 'is too short (minimum is 10 characters)'
  end

  test 'should validate maximum length of question' do
    long_question = 'a' * 501
    faq = Faq.new(question: long_question, answer: 'Valid answer')
    assert_not faq.valid?
    assert_includes faq.errors[:question], 'is too long (maximum is 500 characters)'
  end

  test 'should validate minimum length of answer' do
    faq = Faq.new(question: 'Valid question?', answer: 'Short')
    assert_not faq.valid?
    assert_includes faq.errors[:answer], 'is too short (minimum is 10 characters)'
  end

  test 'should validate maximum length of answer' do
    long_answer = 'a' * 2001
    faq = Faq.new(question: 'Valid question?', answer: long_answer)
    assert_not faq.valid?
    assert_includes faq.errors[:answer], 'is too long (maximum is 2000 characters)'
  end

  test 'should default active to true' do
    faq = Faq.create!(question: 'Valid question?', answer: 'Valid answer')
    assert faq.active
  end

  test 'active scope returns only active FAQs' do
    active_faq = Faq.create!(question: 'Active question?', answer: 'Active answer', active: true)
    inactive_faq = Faq.create!(question: 'Inactive question?', answer: 'Inactive answer', active: false)

    active_faqs = Faq.active
    assert_includes active_faqs, active_faq
    assert_not_includes active_faqs, inactive_faq
  end

  test 'context_for_llm returns formatted FAQ content' do
    Faq.create!(question: 'What is this chatbot for?', answer: 'This is a test chatbot', active: true)
    Faq.create!(question: 'How does this work?', answer: 'It works very well', active: true)
    Faq.create!(question: 'Is this inactive?', answer: 'Should not appear', active: false)

    context = Faq.context_for_llm
    assert_includes context, 'Q: What is this chatbot for?'
    assert_includes context, 'A: This is a test chatbot'
    assert_includes context, 'Q: How does this work?'
    assert_includes context, 'A: It works very well'
    assert_not_includes context, 'Should not appear'
  end
end
