require "rails_helper"

RSpec.feature "Determine student Loan plan" do
  let(:claim_school) { create(:school, :tslr_eligible, name: "Claim School") }
  let(:claim) do
    create(:tslr_claim,
      claim_school: claim_school)
  end

  before do
    allow_any_instance_of(ClaimsController).to receive(:current_claim) { claim }
    visit claim_path("student-loan")
  end

  context "when the teacher no longer has a student loan" do
    scenario "they skip to the student loan amount question" do
      choose "No"
      click_on "Continue"

      expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))
    end
  end

  context "when the teacher has a student loan" do
    before do
      choose "Yes"
      click_on "Continue"
    end

    scenario "they are asked which country they received their student loan in" do
      expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_country"))
    end

    context "and they received their loan in Scotland" do
      before do
        choose "Scotland"
        click_on "Continue"
      end

      scenario "they see the student loan amount question next" do
        expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))
      end
    end

    context "and they received their loan in Wales" do
      before do
        choose "Wales"
        click_on "Continue"
      end

      scenario "they are asked how many courses they studied" do
        expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_how_many_courses.question"))
      end

      context "and they only studied one course" do
        before do
          choose "1 course"
          click_on "Continue"
        end
        scenario "they see the start date question for a single course" do
          expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_start_date.single_course"))
          expect(page).not_to have_text("Some of my degree courses started before 1 September 2012 and some started after 1 September 2012")
        end
      end

      context "and they only studied two or more courses" do
        before do
          choose "2 or more courses"
          click_on "Continue"
        end
        scenario "they see the start date question for more than one course" do
          expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_start_date.multiple_courses"))
          expect(page).to have_text("Some of my degree courses started before 1 September 2012 and some started after 1 September 2012")
        end
      end
    end
  end
end
