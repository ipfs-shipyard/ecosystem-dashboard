xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @page_title
    xml.description @page_description
    xml.link request.original_url

    @search_results.each do |search_result|
      xml.item do
        xml.title search_result.title
        xml.pubDate search_result.created_at.to_s(:rfc822)
        xml.link search_result.html_url
        xml.guid search_result.html_url
      end
    end
  end
end
