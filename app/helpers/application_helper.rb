module ApplicationHelper
   include Pagy::Frontend

   def collab_title
     params[:collab].presence || 'collab'
   end

   def language_title(lang)
     case lang
     when 'py'
       'Python'
     when 'cs'
       'C#'
     else
       lang
     end
   end
end
