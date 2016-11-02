This plugin adds an API endpoint (/repositories/:repo_id/browse_pages) that parses all published Resources and updates a separate MySQL database with the following information for each Resource:
* Resource ID
* EAD ID
* Display title
* Sort name
* Page (a-z)
* Classification (U of M or A-Z)
* Status (new, updated, or none)

To use this plugin, add the following line to `config.rb` pointing at the external MySQL database:
AppConfig[:browse_page_db_url]