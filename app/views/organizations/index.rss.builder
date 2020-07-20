xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @orgs.each do |org|
      xml.item do
        xml.title org.name
        xml.pubDate org.created_at.to_s(:rfc822)
        xml.link org_url(org)
        xml.guid org_url(org)
      end
    end
  end
end
