class Meeting < ApplicationRecord
  belongs_to :lead
  belongs_to :user
end
