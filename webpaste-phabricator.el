;;; webpaste-phabricator.el --- Paste to Phabricator  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Mr Maker

;; Author: Mr Maker <make-all@users.github.com>
;; Version: 0.1.0
;; URL: https://github.com/make-all/webpaste-phabricator#readme
;; Package-Requires: ((emacs "24.4") (webpaste "1.5.0") (request "0.2.0"))

;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides backend support for using Phabricator Paste
;; application as a provider for webpaste.el.

;; To work more easily with webpaste.el's assumptions about http posting,
;; it uses the "simple" query parameter API of conduit rather than the
;; JSON API, so does not use conduit.el for the API calls.  However, it can
;; make use of the conduit.el configuration if you have it installed to
;; avoid re-specifying your server and credentials when you call
;; `webpaste-phabricator-add-provider'.

;; Since `webpaste-phabricator-add-provider' can take optional url and token
;; arguments, it is possible to configure multiple Phabricator servers
;; as webpaste providers.

;; Note:
;; Using `webpaste-phabricator-add-provider' will leave
;; `webpaste-providers-alist' in "changed outside Customize" state.
;; It is not recommended to save any customizations to this variable
;; if you are using this package.

;; Example Usage;

;;   ;; Add a provider for the conduit.el configured server.
;;   (webpaste-phabricator-add-provider)
;;   ;; Add a provider for a specific Phabricator server.
;;   (webpaste-phabricator-add-provider "https://example.phacility.com/"
;;                                      "api-xxxxxxxxxxxxxxxxxxxxxxxxxxxx")
;;   ;; ...Configure webpaste-provider-priority etc as normal.

;;; Code:
(require 'url-parse)
(require 'request)
(require 'webpaste)

(defvar webpaste-phabricator-language-overrides
  '((apache-mode . "apacheconf")
    (shell-script-mode . "bash")
    (brainfuck-mode . "brainfuck")
    (c-mode . "c")
    (coffee-mode . "coffee-script")
    (c++-mode . "cpp")
    (csharp-mode . "csharp")
    (d-mode . "d")
    (diff-mode . "diff")
    (django-mode . "django")
    (django-html-mode . "django")
    (dockerfile-mode . "docker")
    ;; There is a pygments module for elisp, but it needs separate installation
    ;; Since scheme now includes a lot of elisp keywords, it is closest of the
    ;; default lexers.
    (emacs-lisp-mode . "scheme")
    (erlang-mode . "erlang")
    (groovy-mode . "groovy")
    (haskell-mode . "haskell")
    (html-helper-mode . "html")
    (nxhtml-mode . "html")
    (sgml-mode . "html")
    (yahtml-mode . "html")
    (jde-mode . "java")
    (malabar-mode . "java")
    (js2-mode . "js")
    (javascript-mode . "js")
    (json-mode . "json")
    (makefile-mode . "make")
    (nginx-mode . "nginx")
    (objc-mode . "objc")
    (perl-mode . "perl")
    (po-mode . "pot")
    (puppet-mode . "puppet")
    (markdown-mode . "markdown")
    (rst-mode . "rst")
    (robot-mode . "robotframework")
    (ruby-mode . "ruby")
    (scheme-mode . "scheme")
    (sql-mode . "sql")
    (tex-mode . "tex")
    (latex-mode . "tex")
    (text-mode . "text")
    (twig-mode . "twig")
    (xml-mode . "xml")
    (nxml-mode . "xml"))
  "Alist that maps `major-mode' names to language names in Phabricator.
This is combined with webpaste--default-lang-alist, so only includes
additional languages available in Phabricator, and alternate modes missed
from the default.")

(cl-defun webpaste-phabricator-success-result ()
  "Success callback for phabricator webpaste provider.
Parses the JSON response to get the URL for the newly created paste."
  (cl-function
   (lambda (&key data &key response &allow-other-keys)
     (when (and response data)
       (let* ((url (url-generic-parse-url
		    (request-response-url response)))
	      (baseurl (concat (url-type url) "://" (url-host url)
			       (and (url-port-if-non-default url)
				    (concat ":" (url-port url)))
			       "/P")))
	 ;; Retrieve the Paste ID that is deeply nested within
	 ;; the result, and prepend with known URL prefix.
	 (webpaste--return-url
	  (concat baseurl
		  (cdr (assoc "id"
			      (cdr (assoc "object"
					  (cdr (assoc "result"
						      data)))))))))))))


;;;###autoload
(defun webpaste-phabricator-add-provider (&optional url token)
  "Add a phabricator server as a webpaste provider.
The server URL and TOKEN may be provided as args, otherwise they will
be taken from `conduit-phabricator-url' and `conduit-api-token' based
on conduit.el configuration."
  (interactive)
  (or url (boundp 'conduit-phabricator-url) (error "URL not specified and conduit library not available"))
  (or token (boundp 'conduit-api-token) (error "Token not specified and conduit library not available"))
  (let* ((server-url (string-remove-suffix "/"
					   (or url conduit-phabricator-url)))
	 (api-token (or token conduit-api-token))
	 (server-name (url-host (url-generic-parse-url server-url)))
	 (endpoint (concat server-url "/api/paste.edit")))
    (push `(,server-name
	    :uri ,endpoint
	    :post-field "transactions[0][value]"
	    :post-data (("api.token" . ,api-token)
			("transactions[0][type]" . "text")
			("transactions[1][type]" . "language")
			("transactions[2][type]" . "title")
			("transactions[2][value]" . "Paste from Emacs"))
	    :post-lang-field-name "transactions[1][value]"
	    :lang-overrides ,webpaste-phabricator-language-overrides
	    :success-lambda webpaste-phabricator-success-result
	    :parser json-read)
	  webpaste-providers-alist)))

(provide 'webpaste-phabricator)
;;; webpaste-phabricator.el ends here
