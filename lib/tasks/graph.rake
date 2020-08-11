namespace :graph do
  task generate: :environment do
    issues = Issue.internal.not_core.humans.order('repo_full_name').map{|i| [i.user, i.repo_full_name] }.uniq

    s = 'graph G {
    graph [overlap=false,outputorder=edgesfirst,fontname = "helvetica"];
    node [style = filled, color="#aaaaaa"fontname = "helvetica"];
    edge [arrowhead=none,arrowsize=0.5,color="#aaaaaa"fontname = "helvetica"];
    '

    colors = ['#AAEAEF', '#64C2CA', '#1D74F2', '#CDDD40', '#50A5F9', 'turquoise3']

    orgs = issues.map{|u,r| r.split('/').first }.uniq

    size = issues.map{|u,r| r}.group_by{|r| r }.map{|r, is| [r, is.length]}.to_h
    usersize = issues.map{|u,r| u}.group_by{|r| r }.map{|r, is| [r, is.length]}.to_h

    issues.map{|u,r| r}.uniq.each {|r| s+= "\"#{r}\" [fontsize=#{size[r]+5},color=\"#{colors[orgs.index(r.split('/').first)]}\"]\n" }

    issues.map{|u,r| u}.uniq.each {|r| s+= "\"#{r}\" [fontsize=#{usersize[r]+5}]\n" }

    issues.each{|i| s += "\"#{i[0]}\" -- \"#{i[1]}\"\n"};nil

    s += '}'

    File.write('test.gv', s)

    # rake graph:generate && dot -Tjpeg -Kneato test.gv > both.jpeg && open both.jpeg
  end

  task collabs: :environment do
    issues = Issue.internal.not_core.humans.all_collabs.order('repo_full_name').map{|i| [i.collabs.first, i.repo_full_name] }.uniq

    s = 'graph G {
    graph [overlap=false,outputorder=edgesfirst,fontname = "helvetica"];
    node [style = filled, color="#aaaaaa"fontname = "helvetica"];
    edge [arrowhead=none,arrowsize=0.5,color="#aaaaaa"fontname = "helvetica"];
    '

    colors = ['#b266ff', '#F76B5C', '#dddddd', '#AAEAEF', '#64C2CA', '#1D74F2', '#CDDD40', '#50A5F9', 'turquoise3']

    orgs = issues.map{|u,r| r.split('/').first }.uniq

    size = issues.map{|u,r| r}.group_by{|r| r }.map{|r, is| [r, is.length]}.to_h
    usersize = issues.map{|u,r| u}.group_by{|r| r }.map{|r, is| [r, is.length]}.to_h

    issues.map{|u,r| r}.uniq.each {|r| s+= "\"#{r}\" [fontsize=#{size[r]+8},color=\"#{colors[orgs.index(r.split('/').first)]}\"]\n" }

    issues.map{|u,r| u}.uniq.each {|r| s+= "\"#{r}\" [fontsize=#{usersize[r]+8}]\n" }

    issues.each{|i| s += "\"#{i[0]}\" -- \"#{i[1]}\"\n"};nil

    s += '}'

    File.write('test.gv', s)
    # rake graph:generate && dot -Tjpeg -Kneato test.gv > both.jpeg && open both.jpeg 
  end
end
