FactoryBot.define do
  factory :attachment do
    file { File.new('spec/fixtures/sample.csv') }
  end
end
