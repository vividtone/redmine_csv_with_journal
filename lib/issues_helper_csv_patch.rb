require_dependency 'issues_helper'

module IssuesHelperCsvPatch
  def self.included(base)
    base.module_eval do
      include OverrideMethods
      alias_method_chain :issues_to_csv, :journal
    end
  end

  module OverrideMethods
    def issues_to_csv_with_journal(issues, project = nil)
      ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
      decimal_separator = l(:general_csv_decimal_separator)
      export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
        # csv header fields
        headers = [ "#",
                    l(:field_status), 
                    l(:field_project),
                    l(:field_tracker),
                    l(:field_priority),
                    l(:field_subject),
                    l(:field_assigned_to),
                    l(:field_category),
                    l(:field_fixed_version),
                    l(:field_author),
                    l(:field_start_date),
                    l(:field_due_date),
                    l(:field_done_ratio),
                    l(:field_estimated_hours),
                    l(:field_parent_issue),
                    l(:field_created_on),
                    l(:field_updated_on),
                    ]
        # Export project custom fields if project is given
        # otherwise export custom fields marked as "For all projects"
        custom_fields = project.nil? ? IssueCustomField.for_all : project.all_issue_custom_fields
        custom_fields.each {|f| headers << f.name}
        # Description in the last column
        headers << l(:field_description)
        headers << l(:field_notes)
        csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }

        # csv lines
        issues.each do |issue|
          fields = [issue.id,
                    issue.status.name, 
                    issue.project.name,
                    issue.tracker.name, 
                    issue.priority.name,
                    issue.subject,
                    issue.assigned_to,
                    issue.category,
                    issue.fixed_version,
                    issue.author.name,
                    format_date(issue.start_date),
                    format_date(issue.due_date),
                    issue.done_ratio,
                    issue.estimated_hours.to_s.gsub('.', decimal_separator),
                    issue.parent_id,
                    format_time(issue.created_on),  
                    format_time(issue.updated_on)
                    ]
          custom_fields.each {|f| fields << show_value(issue.custom_value_for(f)) }
          fields << issue.description
          latest_journal = issue.journals.reverse.detect {|j| ! j.notes.to_s.empty?}
          if latest_journal
            note_datetime = latest_journal.created_on.strftime("%Y/%m/%d %H:%M")
            note_user = latest_journal.user.lastname + " " + latest_journal.user.firstname
            note = latest_journal.notes
            fields << "(#{note_datetime} #{note_user})\r\n#{note}"
          else
            fields << ""
          end
          csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
        end
      end
      export
    end
  end
end

IssuesHelper.send(:include, IssuesHelperCsvPatch)
