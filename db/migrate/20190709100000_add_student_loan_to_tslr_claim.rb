class AddStudentLoanToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :student_loan, :boolean
  end
end
