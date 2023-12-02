# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/import_issues_csv_email.html.haml' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:correct_results) { { success: 3, valid_file: true } }
  let(:errored_results) { { success: 3, error_lines: [5, 6, 7], valid_file: true } }
  let(:parse_error_results) { { success: 0, parse_error: true } }

  before do
    assign(:user, user)
    assign(:project, project)
  end

  context 'when no errors found while importing' do
    before do
      assign(:results, correct_results)
    end

    it 'renders correctly' do
      render

      expect(rendered).to have_link(project.full_name, href: project_url(project))
      expect(rendered).to have_content("3 issues imported")
      expect(rendered).not_to have_content("Errors found on line")
      expect(rendered).not_to have_content(
        "Error parsing CSV file. Please make sure it has the correct format: \
a delimited text file that uses a comma to separate values.")
    end
  end

  context 'when import errors reported' do
    before do
      assign(:results, errored_results)
    end

    it 'renders correctly' do
      render

      expect(rendered).to have_content("Errors found on lines: #{errored_results[:error_lines].join(", ")}. \
Please check if these lines have an issue title.")
      expect(rendered).not_to have_content("Error parsing CSV file. Please make sure it has the correct format: \
a delimited text file that uses a comma to separate values.")
    end
  end

  context 'when parse error reported while importing' do
    before do
      assign(:results, parse_error_results)
    end

    it 'renders with parse error' do
      render

      expect(rendered).to have_content("Error parsing CSV file. \
Please make sure it has the correct format: a delimited text file that uses a comma to separate values.")
    end
  end
end
