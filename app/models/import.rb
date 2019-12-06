class Import < ApplicationRecord
  enum status: [:active, :in_progress, :finish, :error]

  belongs_to :attachment
end
