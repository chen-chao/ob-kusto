;;; ob-kusto.el --- Integrate Kusto.Cli with org babel   -*- lexical-binding: t; -*-

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

;; Integrate `kusto-cli' with `org-babel'.

;;; Code:

(require 'ob)
(require 'kusto-cli)

(defun org-babel-execute:kusto (body params)
  "Execute a block of Kusto query with Babel.
  This function is called by `org-babel-execute-src-block'."
  (let* ((cluster (cdr (assq :cluster params)))
	 (database (cdr (assq :database params))))
    (pcase (cons (null cluster) (null database))
      ('(nil . nil) (kusto-cli--connect-cluster-database cluster database))
      ('(t . nil) (error "database is set but cluster is empty."))
      ('(nil . t) (error "cluster is set but database is empty."))
      ;; ('(t . t) ) ) do nothing when none of cluster and database is set.
      )
    (kusto-cli--execute-query body)))

(provide 'ob-kusto)
;;; ob-kusto.el ends here
