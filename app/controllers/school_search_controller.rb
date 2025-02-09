class SchoolSearchController < ApplicationController
  def create
    search_schools
    render status: errors.blank? ? :ok : :bad_request
  end

  private

  def search_schools
    if params[:query].blank?
      errors.push("Expected required parameter 'query' to be set")
      return
    end

    begin
      @schools = School.search(params[:query])
    rescue ArgumentError => e
      raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

      errors.push("'query' parameter must have a minimum of four characters")
    end
  end

  def errors
    @errors ||= []
  end
  helper_method :errors
end
