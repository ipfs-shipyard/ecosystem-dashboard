require 'pagy/extras/bootstrap'
require 'pagy/extras/array'
require 'pagy/extras/headers'
require 'pagy/extras/overflow'
require 'pagy/extras/items'

Pagy::VARS[:overflow] = :last_page

Pagy::VARS[:max_items] = 1000
Pagy::VARS[:items_param] = :per_page
