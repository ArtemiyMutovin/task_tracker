FactoryBot.define do
  factory :task_occurrence do
    task
    occurrence_date { Date.today }
    status { 'pending' }
    cancelled { false }

    trait :done do
      status { 'done' }
    end

    trait :cancelled_occurrence do
      cancelled { true }
      status { 'cancelled' }
    end
  end
end
