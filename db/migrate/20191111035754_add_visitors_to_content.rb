class AddVisitorsToContent < ActiveRecord::Migration[5.2]
  def change
    add_column :contents, :visitors, :jsonb
  end
end
