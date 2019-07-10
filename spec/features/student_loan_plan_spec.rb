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
      expect(claim.student_loan_plan).to be_nil
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

    context "which they received in Scotland or Northern Ireland" do
      before do
        choose "Scotland"
        click_on "Continue"
      end

      scenario "their plan is set to “Plan 1” and they see the student loan amount question next" do
        expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))
        expect(claim.student_loan_plan).to eq("plan_1")
      end
    end

    context "which they received in England or Wales" do
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
          expect(claim.student_loan_courses).to eq("one_course")
          expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_start_date.single_course"))
          expect(page).not_to have_text("Some of my degree courses started before 1 September 2012 and some started after 1 September 2012")
        end

        context "before 1 September 2012" do
          scenario "their plan is set to “Plan 1” and they see the student loan amount question" do
            choose "Before 1 September 2012"
            click_on "Continue"

            expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))

            expect(claim.student_loan_start_date).to eq("before_first_september_2012")
            expect(claim.student_loan_plan).to eq("plan_1")
          end
        end

        context "after 1 September 2012" do
          scenario "their plan is set to “Plan 2” and they see the student loan amount question" do
            choose "On or after 1 September 2012"
            click_on "Continue"

            expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))

            expect(claim.student_loan_start_date).to eq("on_or_after_first_september_2012")
            expect(claim.student_loan_plan).to eq("plan_2")
          end
        end
      end

      context "and they studied two or more courses" do
        before do
          choose "2 or more courses"
          click_on "Continue"
        end
        scenario "they see the start date question for more than one course" do
          expect(claim.student_loan_courses).to eq("two_or_more_courses")
          expect(page).to have_text(I18n.t("tslr.questions.student_loan_repayment_plan.student_loan_start_date.multiple_courses"))
          expect(page).to have_text("Some of my degree courses started before 1 September 2012 and some started after 1 September 2012")
        end

        context "before 1 September 2012" do
          scenario "their plan is set to “Plan 1” and they see the student loan amount question" do
            choose "All my degree courses started before 1 September 2012"
            click_on "Continue"

            expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))

            expect(claim.student_loan_start_date).to eq("before_first_september_2012")
            expect(claim.student_loan_plan).to eq("plan_1")
          end
        end

        context "some before and some after 1 September 2012" do
          scenario "their plan is set to “Plan 1 and Plan 2” and they see the student loan amount question" do
            choose "Some of my degree courses started before 1 September 2012 and some started after 1 September 2012"
            click_on "Continue"

            expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))

            expect(claim.student_loan_start_date).to eq("some_before_some_after_first_september_2012")
            expect(claim.student_loan_plan).to eq("plan_1_and_2")
          end
        end

        context "after 1 September 2012" do
          scenario "their plan is set to “Plan 2” and they see the student loan amount question" do
            choose "All of my degree courses started after 1 September 2012"
            click_on "Continue"

            expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))

            expect(claim.student_loan_start_date).to eq("on_or_after_first_september_2012")
            expect(claim.student_loan_plan).to eq("plan_2")
          end
        end
      end
    end
  end
end
