FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    system { false }

    trait :system do
      system { true }
    end
  end
end
