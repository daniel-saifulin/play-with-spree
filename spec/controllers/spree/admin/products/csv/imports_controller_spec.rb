require 'rails_helper'
require 'csv'

RSpec.describe Spree::Admin::Products::Csv::ImportsController, type: :controller do
  stub_authorization!

  describe 'GET new' do
    it 'return 200' do
      get :new
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET show' do
    let(:import) { create(:import) }

    it 'returns 200' do
      get :show, params: {id: import.id}
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST create' do
    context "send csv file" do
      it 'returns 302' do
        post :create, params: { csv: fixture_file_upload('spec/fixtures/sample.csv') }
        expect(response).to have_http_status(302)
      end

      it 'calls worker' do
        expect(ProductImportWorker).to receive(:perform_async)
        post :create, params: { csv: fixture_file_upload('spec/fixtures/sample.csv') }
      end

      it 'returns success message' do
        post :create, params: { csv: fixture_file_upload('spec/fixtures/sample.csv') }
        expect(response.request.flash[:notice]).to_not be_nil
      end
    end

    context "send not csv file" do
      it 'returns ok http status' do
        post :create, params: { csv: fixture_file_upload('spec/fixtures/sample.xlsx') }
        expect(response).to have_http_status(200)
      end

      it 'returns error message' do
        post :create, params: { csv: fixture_file_upload('spec/fixtures/sample.xlsx') }
        expect(response.request.flash[:error]).to_not be_nil
      end
    end

    context "send nothing" do
      it 'returns ok http status' do
        post :create
        expect(response).to have_http_status(200)
      end

      it 'returns error message' do
        post :create
        expect(response.request.flash[:error]).to eq "Error: File can't be blank"
      end
    end
  end
end