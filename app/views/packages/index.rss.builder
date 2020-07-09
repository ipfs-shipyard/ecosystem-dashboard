xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @packages.each do |package|
      xml.item do
        xml.title package.name
        xml.description package.description
        xml.pubDate package.created_at.to_s(:rfc822)
        xml.link package_url(package)
        xml.guid package_url(package)
      end
    end
  end
end
