FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    description { "Task description" }
    status { 'pending' }
    due_date { Date.today + 1 }
    recurrence_type { nil }
    recurrence_params { {} }

    trait :done do
      status { 'done' }
    end

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :daily do
      due_date { nil }
      starts_on { Date.today }
      recurrence_type { 'daily' }
      recurrence_params { { 'interval' => 1 } }
    end

    trait :every_two_days do
      due_date { nil }
      starts_on { Date.today }
      recurrence_type { 'daily' }
      recurrence_params { { 'interval' => 2 } }
    end

    trait :monthly do
      due_date { nil }
      starts_on { Date.today.beginning_of_month }
      recurrence_type { 'monthly' }
      recurrence_params { { 'day' => 15 } }
    end

    trait :specific_dates do
      due_date { nil }
      starts_on { Date.today }
      recurrence_type { 'specific_dates' }
      recurrence_params { { 'dates' => [ Date.today.to_s, (Date.today + 7).to_s ] } }
    end

    trait :even_days do
      due_date { nil }
      starts_on { Date.today.beginning_of_month }
      recurrence_type { 'even_odd' }
      recurrence_params { { 'parity' => 'even' } }
    end

    trait :odd_days do
      due_date { nil }
      starts_on { Date.today.beginning_of_month }
      recurrence_type { 'even_odd' }
      recurrence_params { { 'parity' => 'odd' } }
    end
  end
end
