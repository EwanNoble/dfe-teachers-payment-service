require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    claim = start_claim
    expect(page).to have_text(I18n.t("student_loans.questions.qts_award_year"))

    choose_qts_year
    expect(claim.eligibility.reload.qts_award_year).to eql("2014_2015")
    expect(page).to have_text(I18n.t("student_loans.questions.claim_school"))

    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))

    choose_still_teaching
    expect(claim.eligibility.reload.employment_status).to eql("claim_school")
    expect(claim.eligibility.current_school).to eql(schools(:penistone_grammar_school))

    expect(page).to have_text(I18n.t("student_loans.questions.subjects_taught"))
    check "Physics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("student_loans.questions.mostly_teaching_eligible_subjects", subjects: "Physics"))
    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.mostly_teaching_eligible_subjects?).to eq(true)

    expect(page).to have_text("You are eligible to claim back student loan repayments")

    perform_verify_step

    expect(claim.reload.full_name).to eql("Isambard Kingdom Brunel")
    expect(claim.address_line_1).to eql("Verified Street")
    expect(claim.address_line_2).to eql("Verified Town")
    expect(claim.address_line_3).to eql("Verified County")
    expect(claim.postcode).to eql("M12 345")
    expect(claim.date_of_birth).to eq(Date.new(1806, 4, 9))
    expect(claim.payroll_gender).to eq("male")

    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))
    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    expect(page).to have_text(I18n.t("questions.national_insurance_number"))
    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    expect(claim.reload.national_insurance_number).to eq("QQ123456C")

    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    answer_student_loan_plan_questions

    expect(claim.reload).to have_student_loan
    expect(claim.student_loan_country).to eq("england")
    expect(claim.student_loan_courses).to eq("one_course")
    expect(claim.student_loan_start_date).to eq(StudentLoans::BEFORE_1_SEPT_2012)
    expect(claim.student_loan_plan).to eq(StudentLoans::PLAN_1)

    expect(page).to have_text(I18n.t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name))
    fill_in I18n.t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name), with: "1100"
    click_on "Continue"

    expect(claim.eligibility.reload.student_loan_repayment_amount).to eql(1100.00)

    expect(page).to have_text(I18n.t("questions.email_address"))
    expect(page).to have_text("We will only use your email address to update you about your claim.")
    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    expect(claim.reload.email_address).to eq("name@example.tld")

    expect(page).to have_text(I18n.t("questions.bank_details"))
    expect(page).to have_text("The account you want us to send your payment to.")
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    expect(page).to have_text("Check your answers before sending your application")

    freeze_time do
      perform_enqueued_jobs do
        expect {
          click_on "Confirm and send"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    expect(page).to have_text("Claim submitted")
    expect(page).to have_text(claim.reference)
    expect(page).to have_text(claim.email_address)
  end
end
