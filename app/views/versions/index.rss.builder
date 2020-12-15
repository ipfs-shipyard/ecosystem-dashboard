xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @versions.each do |version|
      xml.item do
        xml.title version.number
        xml.description version.number
        xml.pubDate version.created_at.to_s(:rfc822)
        xml.link package_version_url(package_id: version.package.id, id: version.id)
        xml.guid package_version_url(package_id: version.package.id, id: version.id)
      end
    end
  end
end
