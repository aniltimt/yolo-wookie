require 'tempfile'

class Paperclip::Xmlize < Paperclip::Processor
  def make
   xmlized_content = ""
    
    xml = Builder::XmlMarkup.new(:target => xmlized_content)
    xml.instruct!
    xml.data do
      xml.text do |t|
        t << self.file.read   #  doing 't << value' rather then 'xml.text value' will save the value w/o encoding into html entities
      end
    end

    tf = ::Tempfile.open(File.basename(self.file.path))
    tf.write xmlized_content

    return tf
  end
  
end
