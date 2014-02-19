class TextPage < Medium
  has_attached_file :attachment, :styles => { :original => {} }, :processors => [:xmlize]
end
