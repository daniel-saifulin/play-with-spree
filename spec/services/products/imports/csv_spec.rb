require "rails_helper"

describe Products::Imports::Csv, type: :service do
  subject(:service) { described_class.new(attachment, import) }

  after(:each) { File.delete(file_path) }

  let(:columns) { ";name;description;price;availability_date;slug;stock_total;category" }
  let(:file_path) { "tmp/test.csv" }
  let!(:csv) do
    CSV.open(file_path, "w") do |csv|
      rows.each do |row|
        csv << row.split(",")
      end
    end
  end

  context "#call" do
    context "when csv data are valid" do
      let(:row) { ";Ruby;;22,99;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags" }
      let(:rows) { [columns, row] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      let(:result) do
        product = Spree::Product.first

        {
          name: product.name,
          description: product.description,
          slug: product.slug,
          price: product.price.to_s,
          availability_on: product.available_on.to_s
        }
      end

      let(:expected_result) do
        {
          name: 'Ruby',
          description: nil,
          price: '22.99',
          slug: 'ruby-on-rails-bag',
          availability_on: '2017-12-04 14:55:22 UTC'
        }
      end

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 1
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 0
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 1
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 1
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 1
      end

      it "returns saved product's data" do
        service.call
        expect(expected_result).to eq result
      end
    end

    context "when csv data are duplicate" do
      let(:row) { ";Ruby;;22,99;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags" }
      let(:row2) { ";Ruby;;22,99;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags" }
      let(:rows) { [columns, row, row2] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      let(:result) do
        product = Spree::Product.first

        {
          name: product.name,
          description: product.description,
          slug: product.slug,
          price: product.price.to_s,
        }
      end

      let(:expected_result) do
        {
          name: 'Ruby',
          description: nil,
          price: '22.99',
          slug: 'ruby-on-rails-bag'
        }
      end

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 2
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 0
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 1
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 1
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 1
      end

      it "returns saved product's data" do
        service.call
        expect(expected_result).to eq result
      end
    end

    context "when name is missing" do
      let(:row) { ";;;22,99;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags" }
      let(:rows) { [columns, row] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 0
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 1
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 0
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 0
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 0
      end
    end

    context "when price is missing" do
      let(:row) { ";ruby;;;2017-12-04T14:55:22.913Z;ruby-on-rails-bag;15;Bags" }
      let(:rows) { [columns, row] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 0
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 1
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 0
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 0
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 0
      end
    end

    context "when slug is missing" do
      let(:row) { ";ruby;;22,99;2017-12-04T14:55:22.913Z;;15;Bags" }
      let(:rows) { [columns, row] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      let(:result) do
        product = Spree::Product.first

        {
          name: product.name,
          description: product.description,
          slug: product.slug,
          price: product.price.to_s,
        }
      end

      let(:expected_result) do
        {
          name: 'ruby',
          description: nil,
          price: '22.99',
          slug: nil
        }
      end

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 1
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 0
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 1
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 1
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 1
      end

      it "returns saved product's data" do
        service.call
        expect(expected_result).to eq result
      end
    end

    context "when availability_date is missing" do
      let(:row) { ";ruby;;22,99;;slug-123;15;Bags" }
      let(:rows) { [columns, row] }
      let(:attachment) { create(:attachment, file: File.new(file_path)) }
      let(:import) { create(:import, attachment_id: attachment.id) }

      let(:result) do
        product = Spree::Product.first

        {
          name: product.name,
          description: product.description,
          slug: product.slug,
          price: product.price.to_s,
        }
      end

      let(:expected_result) do
        {
          name: 'ruby',
          description: nil,
          price: '22.99',
          slug: 'slug-123'
        }
      end

      it "import has success data" do
        service.call
        expect(import.data['success_count']).to eq 1
      end

      it "import hasn't failure data" do
        service.call
        expect(import.data['failure_count']).to eq 0
      end

      it "create one product" do
        service.call
        expect(Spree::Product.count).to eq 1
      end

      it "create one variant" do
        service.call
        expect(Spree::Variant.count).to eq 1
      end

      it "create one price" do
        service.call
        expect(Spree::Price.count).to eq 1
      end

      it "returns saved product's data" do
        service.call
        expect(expected_result).to eq result
      end
    end
  end
end