FactoryBot.define do
  factory :claim do
    association(:eligibility, factory: :student_loans_eligibility)

    trait :submittable do
      full_name { "Jo Bloggs" }
      address_line_1 { "1 Test Road" }
      postcode { "AB1 2CD" }
      date_of_birth { 20.years.ago.to_date }
      teacher_reference_number { "1234567" }
      national_insurance_number { "QQ123456C" }
      has_student_loan { true }
      student_loan_country { :england }
      student_loan_courses { :one_course }
      student_loan_start_date { StudentLoans::BEFORE_1_SEPT_2012 }
      student_loan_plan { StudentLoans::PLAN_1 }
      email_address { "test@email.com" }
      bank_sort_code { 123456 }
      bank_account_number { 12345678 }

      association(:eligibility, factory: [:student_loans_eligibility, :eligible])
      payroll_gender { :female }
    end

    trait :submitted do
      submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end

    trait :ineligible do
      submittable
      association(:eligibility, factory: [:student_loans_eligibility, :ineligible])
    end
  end
end
