class AddLinkingTripIdToRepeatingTrips < ActiveRecord::Migration[5.1]
  def change
    add_column :repeating_trips, :linking_trip_id, :integer
    add_index :repeating_trips, :linking_trip_id
  end
end
