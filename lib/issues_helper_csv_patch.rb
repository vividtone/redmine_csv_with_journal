require_dependency 'queries_helper'

module QueriesHelperCsvPatch
  def self.included(base)
    base.module_eval do
      include OverrideMethods
      alias_method_chain :query_to_csv, :journal
    end
  end

  module OverrideMethods
    def query_to_csv_with_journal(items, query, options={})
      encoding = l(:general_csv_encoding)
      columns = (options[:columns] == 'all' ? query.available_inline_columns : query.inline_columns)
      query.available_block_columns.each do |column|
        if options[column.name].present?
          columns << column
        end
      end

      export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
        # csv header fields
        csv << columns.collect {|c| Redmine::CodesetUtil.from_utf8(c.caption.to_s, encoding) }
        # csv lines
        items.each do |item|
          # begin patch
          colvalues = columns.collect {|c| Redmine::CodesetUtil.from_utf8(csv_content(c, item), encoding) }
          if options[:description] && item.is_a?(Issue)
            latest_journal = item.journals.reverse.detect {|j| ! j.notes.to_s.empty?}
            if latest_journal
              note_datetime = latest_journal.created_on.strftime("%Y/%m/%d %H:%M")
              note_user = latest_journal.user.lastname + " " + latest_journal.user.firstname
              note = latest_journal.notes
              colvalues << Redmine::CodesetUtil.from_utf8("(#{note_datetime} #{note_user})\r\n#{note}!!!", encoding)
            end
          end
          csv << colvalues
          # end patch
        end
      end
      export  
    end
  end
end

QueriesHelper.send(:include, QueriesHelperCsvPatch)
