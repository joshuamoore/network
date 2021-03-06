class NetworkEvent < ApplicationRecord
  validates :name, presence: true
  validates :program_id, presence: true
  validates :location_id, presence: true
  before_save :apply_date_modifiers_to_tasks
  

  belongs_to :location
  belongs_to :user
  belongs_to :program

  has_many :site_contact_assignments, dependent: :delete_all
  has_many :site_contacts, through: :site_contact_assignments, source: :member

  has_many :school_contact_assignments, dependent: :delete_all
  has_many :school_contacts, through: :school_contact_assignments, source: :member

  has_many :volunteer_assignments, dependent: :delete_all
  has_many :volunteers, through: :volunteer_assignments, source: :member

  has_many :graduating_class_assignments, dependent: :delete_all
  has_many :graduating_classes, through: :graduating_class_assignments

  has_many :organization_assignments, dependent: :delete_all
  has_many :organizations, through: :organization_assignments

  has_many :school_assignments, dependent: :delete_all
  has_many :schools, through: :school_assignments

  has_many :cohort_assignments, dependent: :delete_all
  has_many :cohorts, through: :cohort_assignments

  has_many :participations, dependent: :delete_all
  has_many :participants, through: :participations, source: :member

  has_many :network_event_tasks

  accepts_nested_attributes_for :network_event_tasks


  def self.in_date_range(start_date, end_date)
    start_date = Date.strptime(start_date, '%A %B %d %Y')
    end_date = Date.strptime(end_date, '%A %B %d %Y')
    where(scheduled_at: [start_date.beginning_of_day..end_date.end_of_day, nil])
  end

  def self.default_date_range
    start_date= Date.today
    end_date = Date.today + 6.days
    where(scheduled_at: [start_date.beginning_of_day..end_date.end_of_day, nil])
  end

  def self.statuses
    [
      "working",
      "confirmed",
      "scheduled",
      "completed",
      "declined",
      "need to contact and pending further convo with supervisor"
    ]
  end

  def date
    if scheduled_at.present?
      scheduled_at.to_date
    else
      nil
    end
  end

  def invitees
    if cohorts.any? || schools.any? || graduating_classes.any?
      member_scope = Member.distinct

      if cohorts.any?
        member_scope = member_scope.
          joins(:cohorts).
          where(cohorts: { id: cohort_ids }).
          having("COUNT(cohorts.id) = #{cohort_ids.count}").
          group("members.id")
      end

      if schools.any?
        member_scope = member_scope.where(school_id: school_ids)
      end

      if graduating_classes.any?
        member_scope = member_scope.where(graduating_class_id: graduating_class_ids)
      end
    else
      member_scope = Member.none
    end

    member_scope
  end

  def location_name
    location.try(:name)
  end

  def name_with_date
    if scheduled_at.present?
      name + ' (' + scheduled_at.to_formatted_s(:long) + ')'
    else
      name
    end
  end

  def program_name
    program.try(:name)
  end

  def start_time
    if scheduled_at.present?
      scheduled_at.to_time
    else
      nil
    end
  end

  def stop_time
    if scheduled_at.present?
      (scheduled_at + duration.minutes).to_time
    else
      nil
    end
  end
  
  protected
  
  def apply_date_modifiers_to_tasks
    attribute = 'scheduled_at'
    # If scheduled_at changed, re/apply datemodifier to get correct task due dates
    if self.changes.include? attribute
      self.network_event_tasks.each do |task|
        if task.date_modifier
          scheduled_at = self.scheduled_at.in_time_zone("Central Time (US & Canada)")
          puts case task.date_modifier
          when 'Monday before event'
            task.due_date = scheduled_at.end_of_week(:tuesday) - 1.week
          when '2 Mondays before event'
            task.due_date = scheduled_at.end_of_week(:tuesday) - 2.weeks
          when 'Friday before event'
            task.due_date = scheduled_at.end_of_week(:saturday) - 1.week
          when '2 Fridays before event'
            task.due_date = scheduled_at.end_of_week(:saturday) - 2.weeks
          when '1 week before event'
            task.due_date = scheduled_at.end_of_day - 1.week
          when '2 weeks before event'
            task.due_date = scheduled_at.end_of_day - 2.weeks
          when '3 weeks before event'
            task.due_date = scheduled_at.end_of_day - 3.weeks
          when '1 month before event'
            task.due_date = scheduled_at.end_of_day - 1.months
          when '2 months before event'
            task.due_date = scheduled_at.end_of_day - 2.months
          when '3 months before event'
            task.due_date = scheduled_at.end_of_day - 3.months
          when '4 months before event'
            task.due_date = scheduled_at.end_of_day - 4.months
          end
        end
      end
    end
  end
end
