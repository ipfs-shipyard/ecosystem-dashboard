module ApplicationHelper
   include Pagy::Frontend

   def collab_title
     params[:collab].presence || 'collab'
   end

   def language_title(lang)
     lang == 'py' ? 'Python' : lang
   end
end
