class Import < ApplicationRecord
  enum status: [:active, :in_progress, :finish, :error]
end
