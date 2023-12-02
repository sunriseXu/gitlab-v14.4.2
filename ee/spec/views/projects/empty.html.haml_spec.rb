# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/empty' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { ProjectPresenter.new(create(:project, :empty_repo), current_user: user) }

  let(:can_admin_project_member) { true }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:project, project)
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('projects/_free_user_cap_alert')
    end
  end
end
