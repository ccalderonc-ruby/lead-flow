# frozen_string_literal: true

class RestructureOpportunityStages < ActiveRecord::Migration[8.1]
  DESIRED = [
    { name: "Prospects", position: 1, default_probability: 20 },
    { name: "Proposal", position: 2, default_probability: 60 },
    { name: "Negotiation", position: 3, default_probability: 80 },
    { name: "Won", position: 4, default_probability: 100 },
    { name: "Lost", position: 5, default_probability: 0 }
  ].freeze

  def up
    # Free unique position slots before renaming / reordering.
    OpportunityStage.order(:id).each_with_index do |stage, index|
      stage.update_columns(position: 1000 + index)
    end

    rename_stage("Prospect", "Prospects")
    rename_stage("Closed", "Lost")

    migrate_opportunities("Qualification", to: "Proposal")
    OpportunityStage.where(name: "Qualification").delete_all

    DESIRED.each do |attrs|
      stage = OpportunityStage.find_or_initialize_by(name: attrs[:name])
      stage.assign_attributes(attrs)
      stage.save!
    end

    keep = DESIRED.map { |attrs| attrs[:name] }
    OpportunityStage.where.not(name: keep).find_each do |stage|
      fallback = OpportunityStage.find_by!(name: "Prospects")
      Opportunity.where(stage_id: stage.id).update_all(stage_id: fallback.id)
      stage.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def rename_stage(from, to)
    stage = OpportunityStage.find_by(name: from)
    return unless stage

    if (existing = OpportunityStage.find_by(name: to))
      Opportunity.where(stage_id: stage.id).update_all(stage_id: existing.id)
      stage.destroy!
    else
      stage.update_columns(name: to)
    end
  end

  def migrate_opportunities(from, to:)
    source = OpportunityStage.find_by(name: from)
    return unless source

    target = OpportunityStage.find_by(name: to)
    return unless target

    Opportunity.where(stage_id: source.id).update_all(stage_id: target.id)
  end
end
