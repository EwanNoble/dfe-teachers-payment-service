module StudentLoans
  class PermittedParameters
    ELIGIBILITY_PARAMETERS = [
      :qts_award_year,
      :claim_school_id,
      :employment_status,
      :current_school_id,
      :mostly_teaching_eligible_subjects,
      :student_loan_repayment_amount,
      StudentLoans::Eligibility::SUBJECT_ATTRIBUTES,
    ].flatten.freeze

    PARAMETERS = [
      :full_name,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :date_of_birth,
      :payroll_gender,
      :teacher_reference_number,
      :national_insurance_number,
      :has_student_loan,
      :student_loan_country,
      :student_loan_courses,
      :student_loan_start_date,
      :email_address,
      :bank_sort_code,
      :bank_account_number,
      eligibility_attributes: ELIGIBILITY_PARAMETERS,
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def keys
      PARAMETERS.dup.tap do |parameters|
        parameters.delete(:payroll_gender) if claim.verified_fields.include?("payroll_gender")
      end
    end
  end
end
