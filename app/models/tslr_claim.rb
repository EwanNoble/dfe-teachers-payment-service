class TslrClaim < ApplicationRecord
  VALID_QTS_YEARS = [
    "2013-2014",
    "2014-2015",
    "2015-2016",
    "2016-2017",
    "2017-2018",
    "2018-2019",
    "2019-2020",
  ].freeze

  SUBJECT_FIELDS = [
    :biology_taught,
    :chemistry_taught,
    :physics_taught,
    :computer_science_taught,
    :languages_taught,
  ].freeze

  TRN_LENGTH = 7

  enum employment_status: {
    claim_school: 0,
    different_school: 1,
    no_school: 2,
  }, _prefix: :employed_at

  belongs_to :claim_school, optional: true, class_name: "School"
  belongs_to :current_school, optional: true, class_name: "School"

  validates :claim_school,                      on: [:"claim-school", :submit], presence: {message: "Select a school from the list"}
  validates :current_school,                    on: [:"current-school", :submit], presence: {message: "Select a school from the list"}

  validates :qts_award_year,                    on: [:"qts-year", :submit], inclusion: {in: ClaimsController.helpers.options_for_qts_award_year.map(&:last), message: "Select the academic year you were awarded qualified teacher status"}

  validates :employment_status,                 on: [:"still-teaching", :submit], presence: {message: "Choose the option that describes your current employment status"}

  validate :at_least_one_subject_chosen,        on: [:"subjects-taught", :submit], unless: ->(c) { c.mostly_teaching_eligible_subjects == false }

  validates :mostly_teaching_eligible_subjects, on: [:"mostly-teaching-eligible-subjects", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}

  validates :full_name,                         on: [:"full-name", :submit], presence: {message: "Enter your full name"}
  validates :full_name,                         length: {maximum: 200, message: "Full name must be 200 characters or less"}

  validates :address_line_1,                    on: [:address, :submit], presence: {message: "Enter your building and street address"}
  validates :address_line_1,                    length: {maximum: 100, message: "Address lines must be 100 characters or less"}

  validates :address_line_2,                    length: {maximum: 100, message: "Address lines must be 100 characters or less"}

  validates :address_line_3,                    on: [:address, :submit], presence: {message: "Enter your town or city"}
  validates :address_line_3,                    length: {maximum: 100, message: "Address lines must be 100 characters or less"}

  validates :postcode,                          on: [:address, :submit], presence: {message: "Enter your postcode"}
  validates :postcode,                          length: {maximum: 11, message: "Postcode must be 11 characters or less"}

  validates :date_of_birth,                     on: [:"date-of-birth", :submit], presence: {message: "Enter your date of birth"}

  validates :teacher_reference_number,          on: [:"teacher-reference-number", :submit], presence: {message: "Enter your teacher reference number"}
  validate :trn_must_be_seven_digits

  validates :national_insurance_number, on: [:"national-insurance-number", :submit], presence: {message: "Enter your National Insurance number"}
  validate  :ni_number_is_correct_format

  validates :student_loan_repayment_amount, on: [:"student-loan-amount", :submit], presence: {message: "Enter your student loan repayment amount"}
  validates_numericality_of :student_loan_repayment_amount, message: "Enter a valid monetary amount",
                                                            allow_nil: true,
                                                            greater_than_or_equal_to: 0,
                                                            less_than_or_equal_to: 99999

  validates :email_address,             on: [:"email-address", :submit], presence: {message: "Enter an email address"}
  validates :email_address,             format: {with: URI::MailTo::EMAIL_REGEXP, message: "Enter an email address in the correct format, like name@example.com"},
                                        length: {maximum: 256, message: "Email address must be 256 characters or less"},
                                        allow_nil: true

  validates :bank_sort_code,            on: [:"bank-details", :submit], presence: {message: "Enter a sort code"}
  validates :bank_account_number,       on: [:"bank-details", :submit], presence: {message: "Enter an account number"}

  validate  :bank_account_number_must_be_eight_digits
  validate  :bank_sort_code_must_be_six_digits

  validate :claim_must_not_be_ineligible, on: :submit

  before_validation :reset_inferred_current_school, if: ->(record) { record.persisted? && record.employment_status_changed? }

  before_save :normalise_trn, if: :teacher_reference_number_changed?
  before_save :normalise_ni_number, if: :national_insurance_number_changed?
  before_save :normalise_bank_account_number, if: :bank_account_number_changed?
  before_save :normalise_bank_sort_code, if: :bank_sort_code_changed?

  delegate :name, to: :claim_school, prefix: true, allow_nil: true
  delegate :name, to: :current_school, prefix: true, allow_nil: true

  scope :submitted, -> { where.not(submitted_at: nil) }

  def submit!
    if submittable?
      self.submitted_at = Time.zone.now
      self.reference = unique_reference
      save!
    else
      false
    end
  end

  def submitted?
    submitted_at.present?
  end

  def submittable?
    valid?(:submit) && !submitted?
  end

  def ineligible?
    ineligible_claim_school? || employed_at_no_school? || not_taught_eligible_subjects_enough?
  end

  def ineligibility_reason
    [
      :ineligible_claim_school,
      :employed_at_no_school,
      :not_taught_eligible_subjects_enough,
    ].find { |eligibility_check| send("#{eligibility_check}?") }
  end

  def full_ineligibility_reason
    case ineligibility_reason
    when :ineligible_claim_school then "#{claim_school_name} is not an eligible school."
    when :employed_at_no_school then "You can only get this payment if you’re still working as a teacher."
    when :not_taught_eligible_subjects_enough then "You must have spent at least half your time teaching an eligible subject."
    else "You can only apply for this payment if you meet the eligibility criteria."
    end
  end

  def address
    [address_line_1, address_line_2, address_line_3, address_line_4, postcode].reject(&:blank?).join(", ")
  end

  def student_loan_repayment_amount=(value)
    super(value.to_s.gsub(/[£,\s]/, ""))
  end

  def subjects_taught
    SUBJECT_FIELDS.select { |s| send(s) == true }
  end

  private

  def ineligible_claim_school?
    claim_school.present? && !claim_school.eligible_for_tslr?
  end

  def not_taught_eligible_subjects_enough?
    mostly_teaching_eligible_subjects == false
  end

  def reset_inferred_current_school
    self.current_school = employed_at_claim_school? ? claim_school : nil
  end

  def normalise_trn
    self.teacher_reference_number = normalised_trn
  end

  def normalised_trn
    teacher_reference_number.gsub(/\D/, "")
  end

  def trn_must_be_seven_digits
    errors.add(:teacher_reference_number, "Teacher reference number must contain seven digits") if teacher_reference_number.present? && normalised_trn.length != TRN_LENGTH
  end

  def normalise_ni_number
    self.national_insurance_number = normalised_ni_number
  end

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "")
  end

  def ni_number_is_correct_format
    errors.add(:national_insurance_number, "Enter a National Insurance number in the correct format") \
      if national_insurance_number.present? && !normalised_ni_number.match(/\A[a-z]{2}[0-9]{6}[a-d]{1}\Z/i)
  end

  def normalise_bank_account_number
    self.bank_account_number = normalised_bank_detail(bank_account_number)
  end

  def normalise_bank_sort_code
    self.bank_sort_code = normalised_bank_detail(bank_sort_code)
  end

  def normalised_bank_detail(bank_detail)
    bank_detail.gsub(/\s|-/, "")
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, "Bank account number must contain eight digits") \
      if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, "Sort code must contain six digits") \
      if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def unique_reference
    loop {
      ref = Reference.new.to_s
      break ref unless self.class.exists?(reference: ref)
    }
  end

  def at_least_one_subject_chosen
    errors.add(:subjects_taught, "Choose a subject, or select \"not applicable\"") unless at_least_one_subject_chosen?
  end

  def at_least_one_subject_chosen?
    SUBJECT_FIELDS.find { |s| send(s) == true }.present?
  end

  def claim_must_not_be_ineligible
    errors.add(:base, full_ineligibility_reason) if ineligible?
  end
end
