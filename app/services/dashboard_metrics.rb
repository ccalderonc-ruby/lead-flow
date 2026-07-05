# frozen_string_literal: true

class DashboardMetrics
  def initialize(user)
    @user = user
  end

  def call
    {
      open_leads: scoped_leads.merge(Lead.open).count,
      overdue_tasks: scoped_tasks.merge(Task.overdue).count,
      upcoming_meetings: scoped_meetings.merge(Meeting.upcoming).count,
      pipeline_value: scoped_opportunities.merge(Opportunity.active_pipeline).sum(:value).to_f
    }
  end

  private

  attr_reader :user

  def scoped_leads
    LeadPolicy::Scope.new(user, Lead).resolve
  end

  def scoped_tasks
    TaskPolicy::Scope.new(user, Task).resolve
  end

  def scoped_meetings
    MeetingPolicy::Scope.new(user, Meeting).resolve
  end

  def scoped_opportunities
    OpportunityPolicy::Scope.new(user, Opportunity).resolve
  end
end
