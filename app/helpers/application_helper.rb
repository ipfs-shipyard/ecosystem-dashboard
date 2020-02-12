module ApplicationHelper
   include Pagy::Frontend

   def collab_title
     params[:collab].presence || 'all collab'
   end
end
