class Picture < Medium
  has_attached_file :attachment, :styles => { :thumb => "75x75>" }
end
