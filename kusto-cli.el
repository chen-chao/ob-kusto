;;; kusto-cli.el --- Interact with Kusto.Cli from emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2023

;; Author: Chao Chen <wenbushi@gmail.com>
;; URL: https://github.com/chen-chao/kusto-cli.el
;; Keywords: convenience, processes

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provide basic functions to interact with Kusto.Cli.exe, which can
;; be used with `org-babel' to execute Kusto queries.

;;; Code:

(defgroup kusto-cli nil
  "Run Kusto.Cli.exe within Emacs."
  :prefix "kusto-cli-"
  :group 'kusto-cli)

(defcustom kusto-cli-command-path "Kusto.Cli.exe"
  "The Kusto.Cli command location."
  :group 'kusto-cli
  :type 'string)

(defcustom kusto-cli-command-args "-lineMode:false"
  "The Kusto.Cli command arguments."
  :group 'kusto-cli
  :type 'string)

(defvar kusto-cli--process nil)

(defun kusto-cli--get-process ()
  (if (null kusto-cli--process)
      (setq kusto-cli--process
	    (start-process "kusto-cli" "*kusto-cli*"
			   kusto-cli-command-path kusto-cli-command-args))
    kusto-cli--process))

(defun kusto-cli--send-command (command)
  (let* (;; remove extra newlines at line's end
	 ;; two newlines are needed because we use block mode
	 (cmd (format "%s\n\n" (string-trim-right command))))
    (process-send-string (kusto-cli--get-process) cmd)))

(defun kusto-cli--connect (connect-string)
  (kusto-cli--execute-command (format "#connect %s" connect-string)))

(defun kusto-cli--connect-cluster-database (cluster database)
  (let ((connect-string
	 (format "#connect \"Data Source=%s;Initial Catalog=%s;AAD Federated Security=True\""
		 cluster database)))
    (kusto-cli--execute-command connect-string)))

(defun kusto-cli--execute-command (command)
  "Execute command and return the result for command as a string."
  (with-current-buffer (process-buffer (kusto-cli--get-process))
    (let* ((result "")
	   (orig-filter (process-filter kusto-cli--process))
	   (filter-func (lambda (process output) (setq result (concat result output)))))
      (set-process-filter kusto-cli--process filter-func)
      (kusto-cli--send-command command)
      (while (not (string-suffix-p "> " result))
	(accept-process-output kusto-cli--process 30))
      (set-process-filter kusto-cli--process orig-filter)
      (string-trim-right result "> "))))

(defun kusto-cli--execute-query (query)
  (let ((regex-connect-string "cluster([^z-a]+?)\\.database([^z-a]+?)"))
    (while (string-match regex-connect-string query)
      (kusto-cli--connect (match-string 0)))
    (kusto-cli--execute-command query)))

(defun kusto-cli--quit ()
  "Quit Kusto.Cli.exe. Return t if the process is alive and killed,
nil otherwise."
  (unless (or (null kusto-cli--process)
	      (not (process-live-p kusto-cli--process)))
    (quit-process kusto-cli--process))
  (setq kusto-cli--process nil)
  t)

(provide 'kusto-cli)

;;; kusto-cli.el ends here
