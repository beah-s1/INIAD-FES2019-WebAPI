class CreateVisitorAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :visitor_attributes do |t|
      t.string :user_id, :null => false
      t.jsonb :visitor_attribute
      t.jsonb :action_history
      t.jsonb :enquete

      t.timestamps
    end
  end
end
