class Video < Medium
  has_attached_file :attachment

  def before_save
    # the strange issue on iPhone when playing a video with "application/mp4" content_type (it refuses to open video on the device)
    if self.attachment.content_type.to_s == "application/mp4"
      self.attachment.instance_write(:content_type, "video/mp4")
    end
  end
end
