require_dependency 'issues_helper'

module IssuesHelperCsvPatch
  def self.included(base)
    base.module_eval do
      include OverrideMethods
      alias_method_chain :issues_to_csv, :journal
    end
  end

  module OverrideMethods
    def issues_to_csv_with_journal(issues, project, query, options={})
      decimal_separator = l(:general_csv_decimal_separator)
      encoding = l(:general_csv_encoding)
      columns = (options[:columns] == 'all' ? query.available_columns : query.columns)

      export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
        # csv header fields
        csv << [ "#" ] + columns.collect {|c| Redmine::CodesetUtil.from_utf8(c.caption.to_s, encoding) } +
          (options[:description] ? [Redmine::CodesetUtil.from_utf8(l(:field_description), encoding)] : [])

        # csv lines
        issues.each do |issue|
          col_values = columns.collect do |column|
            s = if column.is_a?(QueryCustomFieldColumn)
              cv = issue.custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
              show_value(cv)
            else
              value = column.value(issue)
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              elsif value.is_a?(Float)
                ("%.2f" % value).gsub('.', decimal_separator)
              else
                value
              end
            end
            s.to_s
          end

          latest_journal = issue.journals.reverse.detect {|j| ! j.notes.to_s.empty?}
          if latest_journal
            note_datetime = latest_journal.created_on.strftime("%Y/%m/%d %H:%M")
            note_user = latest_journal.user.lastname + " " + latest_journal.user.firstname
            note = latest_journal.notes
            journal_text = "(#{note_datetime} #{note_user})\r\n#{note}"
          else
            journal_text = ""
          end

          csv << [ issue.id.to_s ] + col_values.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) } +
            (options[:description] ? [Redmine::CodesetUtil.from_utf8(issue.description, encoding)] + [Redmine::CodesetUtil.from_utf8(journal_text, encoding)] : [])
        end
      end
      export
    end
  end
end

IssuesHelper.send(:include, IssuesHelperCsvPatch)
