namespace :rails_async do
  task :no_db_clone do
    task = Rake::Task['db:test:prepare']
    task.clear_actions
    task.clear_prerequisites
  end
end
