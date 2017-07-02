# Phabricator webpaste.el providers

Copyright (C) 2017  Mr Maker

* Author: Mr Maker <make-all@users.github.com>
* Version: 0.1.0
* URL: https://github.com/make-all/webpaste-phabricator#readme
* Package-Requires: ((emacs "24.4") (webpaste "1.5.0") (request "0.2.0"))

* Keywords: convenience

Licensed under the [GPL version 3](http://www.gnu.org/licenses/) or later.

## Commentary

This file provides backend support for using Phabricator Paste
application as a provider for webpaste.el.

To work more easily with webpaste.el's assumptions about http posting,
it uses the "simple" query parameter API of conduit rather than the
JSON API, so does not use conduit.el for the API calls.  However, it can
make use of the conduit.el configuration if you have it installed to
avoid re-specifying your server and credentials when you call
`webpaste-phabricator-add-provider`.

Since `webpaste-phabricator-add-provider` can take optional url and token
arguments, it is possible to configure multiple Phabricator servers
as webpaste providers.

* Note:
Using `webpaste-phabricator-add-provider` will leave
`webpaste-providers-alist` in "changed outside Customize" state.
It is not recommended to save any customizations to this variable
if you are using this package.

## Example Usage

  ;; Add a provider for the conduit.el configured server.
  (webpaste-phabricator-add-provider)
  ;; Add a provider for a specific Phabricator server.
  (webpaste-phabricator-add-provider "https://example.phacility.com/"
                                     "api-xxxxxxxxxxxxxxxxxxxxxxxxxxxx")
  ;; ...Configure webpaste-provider-priority etc as normal.


