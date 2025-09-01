# == Schema Information
#
# Table name: faqs
#
#  id         :integer          not null, primary key
#  question   :text             not null
#  answer     :text             not null
#  active     :boolean          default("1"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_faqs_on_active  (active)
#

class Faq < ApplicationRecord
  validates :question, presence: true, length: { minimum: 10, maximum: 500 }
  validates :answer, presence: true, length: { minimum: 10, maximum: 2000 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def self.context_for_llm
    active.order(:created_at).map do |faq|
      "Q: #{faq.question}\nA: #{faq.answer}"
    end.join("\n\n")
  end
end
