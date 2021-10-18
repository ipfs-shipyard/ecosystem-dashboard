require 'pagy/extras/bootstrap'
require 'pagy/extras/array'
require 'pagy/extras/headers'
require 'pagy/extras/overflow'
require 'pagy/extras/items'

Pagy::DEFAULT[:overflow] = :last_page

Pagy::DEFAULT[:max_items] = 1000
Pagy::DEFAULT[:items_param] = :per_page
