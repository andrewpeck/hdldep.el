;;; test-hog.el -*- lexical-binding: t; -*-

(require 'hdl-deps)
(require 'ert)
(require 'project)

(add-to-list 'treesit-extra-load-path "~/.emacs.d/.local/etc/tree-sitter")
(add-to-list 'treesit-extra-load-path "~/.emacs.d/.local/cache/tree-sitter")

(defmacro hdl-dep-test (file port-list)
  `(ert-deftest ,(intern file) nil
     (should (equal
              ,port-list
              (progn (find-file (concat (locate-dominating-file "." ".git") ,file))
                     (hdldep-graph-current-buffer (project-root (project-current)))
                     (verilog-port-copy)
                     (kill-buffer nil))))))

(hdl-dep-test "test/me0sf/chamber.vhd" '())
