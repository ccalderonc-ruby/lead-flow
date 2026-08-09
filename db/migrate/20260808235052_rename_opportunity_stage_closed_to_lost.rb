# frozen_string_literal: true

class RenameOpportunityStageClosedToLost < ActiveRecord::Migration[8.1]
  def up
    closed = OpportunityStage.find_by(name: "Closed")
    return unless closed

    if (lost = OpportunityStage.find_by(name: "Lost"))
      Opportunity.where(stage_id: closed.id).update_all(stage_id: lost.id)
      closed.destroy!
      lost.update!(position: 5, default_probability: 0)
    else
      closed.update!(name: "Lost", position: 5, default_probability: 0)
    end
  end

  def down
    lost = OpportunityStage.find_by(name: "Lost")
    return unless lost

    if (closed = OpportunityStage.find_by(name: "Closed"))
      Opportunity.where(stage_id: lost.id).update_all(stage_id: closed.id)
      lost.destroy!
    else
      lost.update!(name: "Closed")
    end
  end
end
