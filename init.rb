require 'redmine'

Rails.configuration.to_prepare do
  require_dependency 'issues_helper_csv_patch'
end

Redmine::Plugin.register :redmine_csv_with_journal do
  name 'Redmine Csv With Journal plugin'
  author 'MAEDA Go'
  description "CSV output with issue's latest notes."
  version '20130530'
  url ''
  author_url ''
end
