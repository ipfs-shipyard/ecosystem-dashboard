xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @repositories.each do |repository|
      xml.item do
        xml.title repository.full_name
        xml.pubDate repository.created_at.to_s(:rfc822)
        xml.link repository_url(repository)
        xml.guid repository_url(repository)
      end
    end
  end
end
