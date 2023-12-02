# frozen_string_literal: true

class Projects::MergeRequests::DraftsController < Projects::MergeRequests::ApplicationController
  include Gitlab::Utils::StrongMemoize

  respond_to :json

  before_action :authorize_create_note!, only: [:create, :publish]
  before_action :authorize_admin_draft!, only: [:update, :destroy]
  before_action :authorize_admin_draft!, if: -> { action_name == 'publish' && params[:id].present? }

  urgency :low, [
    :create,
    :update,
    :destroy,
    :publish
  ]

  def index
    drafts = prepare_notes_for_rendering(draft_notes)
    render json: DraftNoteSerializer.new(current_user: current_user).represent(drafts)
  end

  def create
    create_params = draft_note_params.merge(in_reply_to_discussion_id: params[:in_reply_to_discussion_id])
    create_service = DraftNotes::CreateService.new(merge_request, current_user, create_params)

    draft_note = create_service.execute

    prepare_notes_for_rendering(draft_note)

    render json: DraftNoteSerializer.new(current_user: current_user).represent(draft_note)
  end

  def update
    draft_note.update!(draft_note_params)

    prepare_notes_for_rendering(draft_note)

    render json: DraftNoteSerializer.new(current_user: current_user).represent(draft_note)
  end

  def destroy
    DraftNotes::DestroyService.new(merge_request, current_user).execute(draft_note)

    head :ok
  end

  def publish
    result = DraftNotes::PublishService.new(merge_request, current_user).execute(draft_note(allow_nil: true))

    if Feature.enabled?(:mr_review_submit_comment, @project)
      if create_note_params[:note]
        ::Notes::CreateService.new(@project, current_user, create_note_params).execute

        merge_request_activity_counter.track_submit_review_comment(user: current_user)
      end

      if Gitlab::Utils.to_boolean(approve_params[:approve])
        unless merge_request.approved_by?(current_user)
          success = ::MergeRequests::ApprovalService.new(project: @project, current_user: current_user, params: approve_params).execute(merge_request)

          unless success
            return render json: { message: _('An error occurred while approving, please try again.') }, status: :internal_server_error
          end
        end

        merge_request_activity_counter.track_submit_review_approve(user: current_user)
      end
    end

    if result[:status] == :success
      head :ok
    else
      render json: { message: result[:message] }, status: :internal_server_error
    end
  end

  def discard
    DraftNotes::DestroyService.new(merge_request, current_user).execute

    head :ok
  end

  private

  def draft_note(allow_nil: false)
    strong_memoize(:draft_note) do
      draft_notes.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound => e
    # draft_note is allowed to be nil in #publish
    raise e unless allow_nil
  end

  def draft_notes
    return unless current_user

    strong_memoize(:draft_notes) do
      merge_request.draft_notes.authored_by(current_user)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: @project.id).find_by!(iid: params[:merge_request_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def draft_note_params
    params.require(:draft_note).permit(
      :commit_id,
      :note,
      :position,
      :resolve_discussion,
      :line_code
    ).tap do |h|
      # Old FE version will still be sending `draft_note[commit_id]` as 'undefined'.
      # That can result to having a note linked to a commit with 'undefined' ID
      # which is non-existent.
      h[:commit_id] = nil if h[:commit_id] == 'undefined'
    end
  end

  def create_note_params
    params.permit(
      :note
    ).tap do |create_params|
      create_params[:noteable_type] = merge_request.class.name
      create_params[:noteable_id] = merge_request.id
    end
  end

  def approve_params
    params.permit(:approve)
  end

  def prepare_notes_for_rendering(notes)
    return [] unless notes

    notes = Array.wrap(notes)

    # Preload author and access-level information
    DraftNote.preload_author(notes)
    user_ids = notes.map(&:author_id)
    project.team.max_member_access_for_user_ids(user_ids)

    notes.map(&method(:render_draft_note))
  end

  def render_draft_note(note)
    params = { target_id: merge_request.id, target_type: 'MergeRequest', text: note.note }
    result = PreviewMarkdownService.new(@project, current_user, params).execute
    markdown_params = { markdown_engine: result[:markdown_engine], issuable_reference_expansion_enabled: true }

    note.rendered_note = view_context.markdown(result[:text], markdown_params)
    note.users_referenced = result[:users]
    note.commands_changes = view_context.markdown(result[:commands])

    note
  end

  def authorize_admin_draft!
    access_denied! unless can?(current_user, :admin_note, draft_note)
  end

  def authorize_create_note!
    access_denied! unless can?(current_user, :create_note, merge_request)
  end

  def merge_request_activity_counter
    Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
  end
end

Projects::MergeRequests::DraftsController.prepend_mod
