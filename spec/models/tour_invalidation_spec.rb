require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

# describe "event invalidating tours", :shared => true do
#   it "invalidates associated published tours" do
#     @published_tours.all?{ |t| t.reload.obsolete? }.should be_true
#   end

#   it "leaves associated draft tours unchanged" do
#     @draft_tours.all?{ |t| t.reload.draft? }.should be_true
#   end

#   it "updates modification date for obsolete tours" do
#     @obsolete_tours.each{ |t| t.reload.updated_at.should be_close(@changed_object.updated_at, 1.5.second) }
#   end

#   it "does nothing with irrelevant tours" do
#     @irrelevant_tours.all?{ |t| t.reload.updated_at < @changed_object.updated_at }.should be_true
#   end
# end

# describe "Invalidating", Tour, "by" do
#   before(:all) do
#     %w(draft published obsolete irrelevant).each do |tour_type|
#       instance_variable_set("@#{tour_type}_tours", 3.times.map{ Factory :tour })
#     end
#     @published_tours.each{ |t| t.update_attribute(:aasm_state, 'published') }
#     @obsolete_tours.each{ |t| t.update_attribute(:aasm_state, 'obsolete') }

#     @medium = create_medium('spec/fixtures/media/romania.avi')

#     @location = Factory :location
#     @location.media << @medium
#     [@published_tours, @obsolete_tours, @draft_tours].each{ |tours| tours.each{ |tour| tour.locations << @location }}
#     @location.tours(true)

#   end

#   after(:all) do
#     [Tour, Location, Medium].each(&:destroy_all)
#   end

#   describe "updating it's media" do
#     before(:each) do
#       @changed_object = @medium
#       @changed_object.update_attributes(:name => "Foo2")
#     end

#     it_should_behave_like "event invalidating tours"
#   end

#   describe "updating it's location" do
#     before(:each) do
#       @changed_object = @location
#       @changed_object.update_attributes(:name => "New name")
#     end
#     it_should_behave_like "event invalidating tours"
#   end

#   describe "adding location" do
#     before(:each) do
#       @changed_object = Factory :location
#       [@published_tours, @obsolete_tours, @draft_tours].each{ |tours| tours.each{ |tour| tour.locations << @changed_object }}
#     end

#     it_should_behave_like "event invalidating tours"
#   end

#   describe "deleting location" do
#     before(:each) do
#       @changed_object = @location
#       @location.destroy
#     end
#     it_should_behave_like "event invalidating tours"
#   end

#   describe "adding media" do
#     before(:each) do
#       @changed_object = @medium
#       @medium.destroy
#     end
#     it_should_behave_like "event invalidating tours"
#   end

#   describe "adding media" do
#     before(:each) do
#       @changed_object = create_medium("spec/fixtures/media/pylesos.jpg")
#       @location.media << @changed_object
#     end
#   end

#   describe "changing tour info" do
#     before(:each) do
#       @changed_object = @draft_tours.last
#       [@published_tours, @obsolete_tours, @draft_tours].each{ |tours| tours.each{ |tour| tour.update_attributes(:info => "What a pity") }}
#     end
#     it_should_behave_like "event invalidating tours"

#   end
# end
