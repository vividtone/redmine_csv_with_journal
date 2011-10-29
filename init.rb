require 'redmine'
require 'issues_helper_csv_patch'

Redmine::Plugin.register :redmine_csv_with_journal do
  name 'Redmine Csv With Journal plugin'
  author 'MAEDA Go'
  description "CSV output with issue's latest notes."
  version '0.0.1'
  url ''
  author_url ''
end
