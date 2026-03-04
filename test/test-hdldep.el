;;; test-hog.el -*- lexical-binding: t; -*-

(require 'hdldep)
(require 'ert)
(require 'cl-lib)
(require 'project)

(add-to-list 'treesit-extra-load-path "~/.emacs.d/.local/etc/tree-sitter")
(add-to-list 'treesit-extra-load-path "~/.emacs.d/.local/cache/tree-sitter")

(defmacro hdl-dep-test (file expected-edges)
  `(ert-deftest ,(intern file) nil
     (let ((result (hdldep--create-digraph-for-file
                    (concat (locate-dominating-file "." ".git") ,file))))
       (should (cl-subsetp ,expected-edges result :test #'equal))
       (should (cl-subsetp result ,expected-edges :test #'equal)))))

(hdl-dep-test "test/cluster_finder/cluster_packer.v"
              '((cluster_packer . lac)
                (cluster_packer . find_cluster_primaries)
                (cluster_packer . count_clusters)
                (cluster_packer . SRL16E)
                (cluster_packer . cluster_finder)
                (cluster_finder . priority768)
                (cluster_finder . truncate_clusters)))

(hdl-dep-test "test/me0sf/chamber.vhd"
              '((chamber . chamber_pulse_extension)
                (chamber . dav_to_phase)
                (chamber . partition)
                (chamber . segment_selector)
                (chamber_pulse_extension . pulse_extension)
                (partition . dav_to_phase)
                (partition . deghost)
                (partition . pat_unit_mux)
                (partition . priority_encoder)
                (segment_selector . bitonic_sort)
                (pat_unit_mux . dav_to_phase)
                (pat_unit_mux . pat_unit)
                (bitonic_sort . Bitonic_Sorter)
                (bitonic_sort . sortnet_bitonicsort)
                (pat_unit . hit_count)
                (pat_unit . priority_encoder)))
