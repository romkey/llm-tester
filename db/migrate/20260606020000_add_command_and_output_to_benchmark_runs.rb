class AddCommandAndOutputToBenchmarkRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :benchmark_runs, :command, :text
    add_column :benchmark_runs, :output, :text
  end
end
