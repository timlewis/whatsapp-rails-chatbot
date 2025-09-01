class FaqsController < ApplicationController
  before_action :set_faq, only: [ :show, :edit, :update, :destroy ]

  def index
    @faqs = Faq.all.order(:created_at)
  end

  def show
  end

  def new
    @faq = Faq.new
  end

  def edit
  end

  def create
    @faq = Faq.new(faq_params)

    if @faq.save
      redirect_to @faq, notice: 'FAQ was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @faq.update(faq_params)
      redirect_to @faq, notice: 'FAQ was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @faq.destroy
    redirect_to faqs_path, notice: 'FAQ was successfully deleted.'
  end

  private

  def set_faq
    @faq = Faq.find(params[:id])
  end

  def faq_params
    params.require(:faq).permit(:question, :answer, :active)
  end
end
