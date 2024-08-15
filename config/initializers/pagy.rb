require 'pagy/extras/bootstrap'
require 'pagy/extras/array'
require 'pagy/extras/headers'
require 'pagy/extras/overflow'
require 'pagy/extras/limit'

Pagy::DEFAULT[:overflow] = :last_page

Pagy::DEFAULT[:limit_max] = 1000
Pagy::DEFAULT[:limit_param] = :per_page
