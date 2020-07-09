xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description issues_title
    xml.link request.original_url

    @issues.each do |issue|
      xml.item do
        xml.title issue.title
        xml.description issue.body
        xml.pubDate issue.created_at.to_s(:rfc822)
        xml.link issue.html_url
        xml.guid issue.html_url
      end
    end
  end
end
