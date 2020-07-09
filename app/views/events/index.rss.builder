xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @events.each do |event|
      xml.item do
        xml.title event.title
        xml.pubDate event.created_at.to_s(:rfc822)
        xml.link event.html_url
        xml.guid event.html_url
      end
    end
  end
end
