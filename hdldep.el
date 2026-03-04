;;; hdldep.el --- Visualization of HDL dependency trees -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023-2026 Andrew Peck

;; Author: Andrew Peck <peckandrew@gmail.com>
;; URL: https://github.com/andrewpeck/hdldep.el
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Keywords: tools vhdl verilog

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:
;;
;; Run to get a visualization of the dependency tree for the open buffer.
;;
;;; Code:

(require 'project)
(require 'cl-lib)
(require 'subr-x)
(require 'treesit)
(require 'hierarchy)

;;------------------------------------------------------------------------------
;; Hierarchy Display
;;------------------------------------------------------------------------------

(defun hdldep-hierarchy-current-buffer (&optional choose-dir)
  "Display a hierarchy tree for the current buffer using hierarchy.el.
With prefix argument CHOOSE-DIR, prompt for the search directory."
  (interactive "P")
  (require 'hierarchy)
  (let* ((dir (project-root (project-current)))
         (_ (when choose-dir
              (setq dir (read-directory-name "Search Directory:" dir))))
         (edges (hdldep--create-digraph-for-file (buffer-file-name) dir))
         (h (hierarchy-new))
         ;; Build a child->parent lookup from the edge list (instantiator . instantiated)
         (parent-map (make-hash-table))
         (all-nodes nil))
    (dolist (edge edges)
      (let ((parent (car edge))
            (child (cdr edge)))
        ;; Only set parent once; first occurrence wins in a shared-instance DAG
        (unless (gethash child parent-map)
          (puthash child parent parent-map))
        (push parent all-nodes)
        (push child all-nodes)))
    (dolist (node (delete-dups all-nodes))
      (hierarchy-add-tree h node (lambda (item) (gethash item parent-map))))
    (hierarchy-sort h)
    (switch-to-buffer
     (hierarchy-tabulated-display
      h
      (hierarchy-labelfn-indent
       (lambda (item _) (insert (symbol-name item))))))))

;;------------------------------------------------------------------------------
;; Graphviz Generation
;;------------------------------------------------------------------------------

(defun hdldep-graph-current-buffer (&optional choose-dir)
  "Generate and display an SVG dependency graph for the current buffer.
With a prefix argument CHOOSE-DIR, prompt for the search directory instead
of using the project root."
  (interactive "P")
  (let ((dir (project-root (project-current))))
    (when choose-dir
      (setq dir (list (read-directory-name "Search Directory:" dir))))
    (print dir)
    (print (type-of dir))
    (hdldep--graph-buffer (buffer-file-name) dir)))

(defun hdldep--graph-buffer (file &optional searchdir)
  "Write a .gv and .svg dependency graph for FILE, then display the SVG.
SEARCHDIR is the root directory to search for HDL files; defaults to the
project root."
  (let* ((file-base (file-name-base file)))
    (with-temp-file
        (format "%s.gv" file-base)
      (insert (hdldep--gv-for-file file searchdir)))
    (shell-command (format "dot -Tsvg %s.gv -o %s.svg" file-base file-base))
    (with-selected-window (selected-window)
      (switch-to-buffer-other-window (find-file-noselect (format "%s.svg" file-base) t))
      (revert-buffer t t))))

(defun hdldep--gv-for-file (file &optional dir)

  "Search the directory DIR for files and create a digraph for FILE."

  (hdldep--digraph-to-gv
   (hdldep--create-digraph-for-file file dir)))

(defun hdldep--digraph-to-gv (edges)

  "Takes a list of edges and converts it into graphviz dot format.

The list of edges takes the form of, for example:

((partition . deghost)
 (priority_encoder . r)
 (partition . priority_encoder)
 (pat_unit_mux . dav_to_phase)
 (pat_unit . priority_encoder)
 (pat_unit . hit_count)
 (pat_unit_mux . pat_unit)
 (partition . pat_unit_mux)
 (partition . dav_to_phase)
 (chamber . partition)
 (chamber_pulse_extension . pulse_extension)
 (chamber . chamber_pulse_extension)
 (chamber . dav_to_phase))

and returns the equivalent output as a graphviz graph{}"
  (string-join
   (append
    '("graph {\n")
    (mapcar (lambda (edge) (format "   %s -- %s \n"
                                   (car edge)
                                   (cdr edge)))
            edges)
    '("}\n"))))

;;------------------------------------------------------------------------------
;; Dependency Finding
;;------------------------------------------------------------------------------

(defun hdldep--port-similarity (ports-a ports-b)
  "Number of port names in common between PORTS-A and PORTS-B."
  (length (cl-intersection ports-a ports-b)))

(defun hdldep--grep (regexp)
  ""
  (thread-last
    (split-string
     (shell-command-to-string
      (concat "git grep --files-with-matches " regexp)))
    (cl-remove-if-not (lambda (x)
                        (or (hdldep--file-is-vhdl x)
                            (hdldep--file-is-verilog x))))))

(defun hdldep--find-file-for-module (module _dir)
  "Find the file defining MODULE using git grep."
  (let* ((hits (hdldep--grep (shell-quote-argument (symbol-name module))))
         (definitions (cl-remove-if-not
                       (lambda (f)
                         (eq (hdldep--parse-entity-name f) module))
                       hits)))
    (cond
     ((null definitions) nil)
     ((= 1 (length definitions)) (car definitions))
     (t
      ;; Multiple files define MODULE: score by port similarity against
      ;; observed formal port names from instantiation sites in the grep hits.
      (let* ((inst-files (cl-remove-if (lambda (f) (member f definitions)) hits))
             (observed
              (cl-mapcan (lambda (f)
                           (thread-last
                             (hdldep--get-instantiation-info f)
                             (cl-remove-if-not (lambda (i) (eq (car i) module)))
                             (mapcar #'cdr)))
                         inst-files))
             (scored
              (thread-last
                definitions
                (mapcar (lambda (f)
                          (cons (hdldep--port-similarity
                                 (hdldep--parse-port-names f)
                                 observed)
                                f))))))
        (cdr (car (sort scored (lambda (a b) (> (car a) (car b)))))))))))

(defun hdldep--create-digraph-for-file (file &optional dir)
  "Search the directory DIR for files and create a digraph starting from FILE."
  (setq dir (or dir (project-root (project-current))))
  (unless (file-exists-p file)
    (user-error "File %s not found." file))
  (let* ((start (hdldep--parse-entity-name file))
         (visited nil)
         (queue (list (cons start file)))
         edges)
    (while queue
      (let* ((item (pop queue))
             (mod (car item))
             (mod-file (cdr item)))
        (unless (member mod visited)
          (push mod visited)
          (princ (format "Getting edges for file %s...\n" mod-file))
          (dolist (dep (hdldep--get-entities mod-file))
            (push (cons mod dep) edges)
            (unless (member dep visited)
              (when-let* ((dep-file (hdldep--find-file-for-module dep dir)))
                (push (cons dep dep-file) queue)))))))
    (delete-dups edges)))

;;------------------------------------------------------------------------------
;; Language Agnostic Wrapper
;;------------------------------------------------------------------------------

(defun hdldep--file-is-verilog (file)
  "Return non-nil if FILE has a Verilog or SystemVerilog extension."
  (member (file-name-extension file) '("v" "sv")))

(defun hdldep--file-is-vhdl (file)
  "Return non-nil if FILE has a VHDL extension."
  (member (file-name-extension file) '("vhd" "vhdl")))

(defun hdldep--vhdl-or-verilog (file func-vhdl func-verilog)
  "Dispatches function calls to the right flavor of a function."
  (cond ((hdldep--file-is-vhdl file) (funcall func-vhdl file))
        ((hdldep--file-is-verilog file) (funcall func-verilog file))
        (t (error (format  "Unrecognized file format %s" file)))))

(defun hdldep--parse-entity-name (file)
  "Return the top-level entity/module name defined in FILE as a symbol."
  (hdldep--vhdl-or-verilog file
                           #'hdldep--vhdl-parse-entity-name
                           #'hdldep--verilog-parse-entity-name))

(defun hdldep--get-entities (file)
  "Return a list of module/entity name symbols instantiated in FILE."
  (hdldep--vhdl-or-verilog file
                           #'hdldep--vhdl-get-entities
                           #'hdldep--verilog-get-entities))

(defun hdldep--parse-port-names (file)
  "Return a list of declared port name symbols for the top-level entity in FILE."
  (hdldep--vhdl-or-verilog file
                            #'hdldep--vhdl-parse-port-names
                            #'hdldep--verilog-parse-port-names))

(defun hdldep--get-instantiation-info (file)
  "Return an alist of (module-name . formal-port-symbols) for each instantiation in FILE."
  (hdldep--vhdl-or-verilog file
                            #'hdldep--vhdl-get-instantiation-info
                            #'hdldep--verilog-get-instantiation-info))

;;------------------------------------------------------------------------------
;; Tree-sitter Helpers
;;------------------------------------------------------------------------------

(defun hdldep--treesit-parse-entity-name (file language query)
  "Get the top-level module/entity name from FILE.
LANGUAGE is the tree-sitter language symbol.
QUERY must capture the name node as @name."
  (with-temp-buffer
    (message "Opening %s" file)
    (insert-file-contents file)
    (treesit-parser-create language)
    (when-let* ((root (treesit-buffer-root-node language))
                (captures (treesit-query-capture root query))
                (name-node (cdar captures)))
      (intern (treesit-node-text name-node t)))))

(defun hdldep--treesit-try-queries (root queries)
  "Return the first capture from the first query in QUERIES that succeeds.
Queries that raise `treesit-query-error' are silently skipped."
  (catch 'found
    (dolist (query queries)
      (condition-case nil
          (when-let* ((caps (treesit-query-capture root query))
                      (node (cdar caps)))
            (throw 'found (intern (treesit-node-text node t))))
        (treesit-query-error nil)))))

(defun hdldep--treesit-get-entities (file language queries)
  "Get all instantiated module/entity names from FILE.
LANGUAGE is the tree-sitter language symbol.
QUERIES is a list of treesit queries each capturing nodes as @name.
Queries that raise `treesit-query-error' are silently skipped."
  (with-temp-buffer
    (message "Opening %s" file)
    (insert-file-contents file)
    (treesit-parser-create language)
    (let* ((root (treesit-buffer-root-node language))
           (entities nil))
      (dolist (query queries)
        (condition-case nil
            (dolist (capture (treesit-query-capture root query))
              (push (intern (treesit-node-text (cdr capture) t)) entities))
          (treesit-query-error nil)))
      (delete-dups entities))))


;;------------------------------------------------------------------------------
;; Verilog Parsing
;;------------------------------------------------------------------------------

(defun hdldep--verilog-parse-entity-name (file)
  "Get the module name from a Verilog FILE using tree-sitter."
  (with-temp-buffer
    (message "Opening %s" file)
    (insert-file-contents file)
    (treesit-parser-create 'verilog)
    (hdldep--treesit-try-queries
     (treesit-buffer-root-node 'verilog)
     '(((module_declaration (module_header (simple_identifier) @name)))
       ((module_header (simple_identifier) @name))))))

(defun hdldep--verilog-get-entities (file)
  "Get all instantiated module types in Verilog FILE using tree-sitter."
  (hdldep--treesit-get-entities
   file 'verilog
   '("(module_instantiation . (simple_identifier) @name)"
     "(interface_instantiation . (interface_identifier) @name)"
     "(program_instantiation . (program_identifier) @name)")))

(defun hdldep--verilog-parse-port-names (file)
  "Get declared port names from a Verilog FILE using tree-sitter."
  (hdldep--treesit-get-entities
   file 'verilog
   '(((module_ansi_header
       (list_of_port_declarations
        (ansi_port_declaration (port_identifier (simple_identifier) @name))))))))

(defun hdldep--verilog-get-instantiation-info (file)
  "Get alist of (module-name . formal-port-symbols) for each instantiation in FILE."
  (with-temp-buffer
    (message "Opening %s" file)
    (insert-file-contents file)
    (treesit-parser-create 'verilog)
    (let* ((root (treesit-buffer-root-node 'verilog))
           (insts (mapcar #'cdr (treesit-query-capture
                                 root '((module_instantiation) @i))))
           results)
      (dolist (inst insts)
        (let* ((type-cap (treesit-query-capture
                          inst "(module_instantiation . (simple_identifier) @n)"))
               (module-name (when type-cap (intern (treesit-node-text (cdar type-cap) t))))
               (formal-ports
                (mapcar (lambda (c) (intern (treesit-node-text (cdr c) t)))
                        (treesit-query-capture
                         inst "(hierarchical_instance (list_of_port_connections (named_port_connection (port_identifier) @p)))"))))
          (when module-name
            (push (cons module-name formal-ports) results))))
      results)))

;;------------------------------------------------------------------------------
;; VHDL Parsing
;;------------------------------------------------------------------------------

(defun hdldep--vhdl-parse-entity-name (file)
  "Get the entity name from a VHDL FILE using tree-sitter."
  (hdldep--treesit-parse-entity-name
   file 'vhdl
   '((entity_declaration name: (identifier) @name))))

(defun hdldep--vhdl-get-entities (file)
  "Get all instantiated entities in a VHDL FILE using tree-sitter."
  (hdldep--treesit-get-entities
   file 'vhdl
   '(;; entity instantiation: label : entity lib.entity_name port map (...)
     ((entity_instantiation entity: (selected_name suffix: (simple_name) @name)))
     ;; component instantiation: label : component_name port map (...)
     ((component_instantiation component: (simple_name) @name)))))

(defun hdldep--vhdl-parse-port-names (file)
  "Get declared port names from a VHDL FILE using tree-sitter."
  (hdldep--treesit-get-entities
   file 'vhdl
   '(((entity_declaration
       (entity_header
        (port_clause
         (signal_interface_declaration
          (identifier_list (identifier) @name)))))))))

(defun hdldep--vhdl-get-instantiation-info (file)
  "Get alist of (module-name . formal-port-symbols) for each instantiation in FILE."
  (with-temp-buffer
    (message "Opening %s" file)
    (insert-file-contents file)
    (treesit-parser-create 'vhdl)
    (let* ((root (treesit-buffer-root-node 'vhdl))
           (insts (mapcar #'cdr (treesit-query-capture
                                 root '((component_instantiation_statement) @i))))
           results)
      (dolist (inst insts)
        (let* ((name-cap
                (or (treesit-query-capture
                     inst '((entity_instantiation
                             entity: (selected_name suffix: (simple_name) @n))))
                    (treesit-query-capture
                     inst '((component_instantiation component: (simple_name) @n)))))
               (module-name (when name-cap (intern (treesit-node-text (cdar name-cap) t))))
               (formal-ports
                (mapcar (lambda (c) (intern (treesit-node-text (cdr c) t)))
                        (treesit-query-capture
                         inst '((component_map_aspect
                                 (port_map_aspect
                                  (association_list
                                   (named_association_element
                                    formal_part: (simple_name) @p)))))))))
          (when module-name
            (push (cons module-name formal-ports) results))))
      results)))

;;------------------------------------------------------------------------------
;; Memoization
;;------------------------------------------------------------------------------

(when (locate-library "memoize")
  (require 'memoize)

  (defun hdldep--memoize (func)
    "Memoize FUNC unless it has already been memoized."
    (unless (get func :memoize-original-function)
      (memoize func)))

  (hdldep--memoize 'hdldep--get-instantiation-info)
  (hdldep--memoize 'hdldep--parse-port-names)
  (hdldep--memoize 'hdldep--get-entities)
  (hdldep--memoize 'hdldep--parse-entity-name)
  (hdldep--memoize 'hdldep--find-file-for-module))

(provide 'hdldep)
;;; hdldep.el ends here
