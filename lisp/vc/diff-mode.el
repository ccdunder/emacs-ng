;; Copyright (C) 1998-2017 Free Software Foundation, Inc.

(defconst diff-separator-re "^--+ ?$")

;; "index ", "old mode", "new mode", "new file mode" and
;; "deleted file mode" are output by git-diff.
(defconst diff-file-junk-re
  (concat "Index: \\|Prereq: \\|=\\{20,\\}\\|" ; SVN
          "diff \\|index \\|\\(?:deleted file\\|new\\(?: file\\)?\\|old\\) mode\\|=== modified file"))

;; If point is in a diff header, then return beginning
;; of hunk position otherwise return nil.
(defun diff--at-diff-header-p ()
  "Return non-nil if point is inside a diff header."
  (let ((regexp-hunk diff-hunk-header-re)
        (regexp-file diff-file-header-re)
        (regexp-junk diff-file-junk-re)
        (orig (point)))
    (catch 'headerp
      (save-excursion
        (forward-line 0)
        (when (looking-at regexp-hunk) ; Hunk header.
          (throw 'headerp (point)))
        (forward-line -1)
        (when (re-search-forward regexp-file (point-at-eol 4) t) ; File header.
          (forward-line 0)
          (throw 'headerp (point)))
        (goto-char orig)
        (forward-line 0)
        (when (looking-at regexp-junk) ; Git diff junk.
          (while (and (looking-at regexp-junk)
                      (not (bobp)))
            (forward-line -1))
          (re-search-forward regexp-file nil t)
          (forward-line 0)
          (throw 'headerp (point)))) nil)))

  (if (looking-at diff-hunk-header-re) ; At hunk header.
    (let ((pos (diff--at-diff-header-p))
          (regexp diff-hunk-header-re))
      (cond (pos ; At junk diff header.
             (if try-harder
                 (goto-char pos)
               (error "Can't find the beginning of the hunk")))
            ((re-search-backward regexp nil t)) ; In the middle of a hunk.
            ((re-search-forward regexp nil t) ; At first hunk header.
             (forward-line 0)
             (point))
            (t (error "Can't find the beginning of the hunk"))))))
 diff-hunk diff-hunk-header-re "hunk" diff-end-of-hunk diff-restrict-view
 diff-file diff-file-header-re "file" diff-end-of-file)
      (cond ((>= end pos)
	    (t (error "No hunk found"))))))
(defun diff--some-hunks-p ()
  (save-excursion
    (goto-char (point-min))
    (re-search-forward diff-hunk-header-re nil t)))

  (if (not (diff--some-hunks-p))
      (error "No hunks")
    (diff-beginning-of-hunk t)
    (let* ((hunk-bounds (diff-bounds-of-hunk))
           (file-bounds (ignore-errors (diff-bounds-of-file)))
           ;; If the current hunk is the only one for its file, kill the
           ;; file header too.
           (bounds (if (and file-bounds
                            (progn (goto-char (car file-bounds))
                                   (= (progn (diff-hunk-next) (point))
                                      (car hunk-bounds)))
                            (progn (goto-char (cadr hunk-bounds))
                                   ;; bzr puts a newline after the last hunk.
                                   (while (looking-at "^\n")
                                     (forward-char 1))
                                   (= (point) (cadr file-bounds))))
                       file-bounds
                     hunk-bounds))
           (inhibit-read-only t))
      (apply 'kill-region bounds)
      (goto-char (car bounds))
      (ignore-errors (diff-beginning-of-hunk t)))))
  (if (not (diff--some-hunks-p))
      (error "No hunks")
    (diff-beginning-of-hunk t)
    (let ((inhibit-read-only t))
      (apply 'kill-region (diff-bounds-of-file)))
    (ignore-errors (diff-beginning-of-hunk t))))
	(diff-beginning-of-hunk t)
                   (cond
                    ((and (looking-at diff-separator-re)
                          (zerop before) (zerop after))
                     nil)
                    ((and (looking-at diff-file-header-re)
                          (zerop before) (zerop after))
                     ;; No need to query: this is a case where two patches
                     ;; are concatenated and only counting the lines will
                     ;; give the right result.  Let's just add an empty
                     ;; line so that our code which doesn't count lines
                     ;; will not get confused.
                     (save-excursion (insert "\n")) nil)
                    (t
                     (cl-decf before) t)))
    (let* ((other (diff-xor other-file diff-jump-to-old-file))
	   (char-offset (- (point) (diff-beginning-of-hunk t)))
                  (point) (save-excursion (diff-end-of-hunk) (point))))
  (diff-beginning-of-hunk t)
	(diff-hunk-next))))))
  (let* ((char-offset (- (point) (diff-beginning-of-hunk t)))
		(point) (save-excursion (diff-end-of-hunk) (point))))
(defun diff--forward-while-leading-char (char bound)
  "Move point until reaching a line not starting with CHAR.
Return new point, if it was moved."
  (let ((pt nil))
    (while (and (< (point) bound) (eql (following-char) char))
      (forward-line 1)
      (setq pt (point)))
    pt))

  (when (diff--some-hunks-p)
    (save-excursion
      (diff-beginning-of-hunk t)
      (let* ((start (point))
             (style (diff-hunk-style))    ;Skips the hunk header as well.
             (beg (point))
             (props-c '((diff-mode . fine) (face diff-refine-changed)))
             (props-r '((diff-mode . fine) (face diff-refine-removed)))
             (props-a '((diff-mode . fine) (face diff-refine-added)))
             ;; Be careful to go back to `start' so diff-end-of-hunk gets
             ;; to read the hunk header's line info.
             (end (progn (goto-char start) (diff-end-of-hunk) (point))))

        (remove-overlays beg end 'diff-mode 'fine)

        (goto-char beg)
        (pcase style
          (`unified
           (while (re-search-forward "^-" end t)
             (let ((beg-del (progn (beginning-of-line) (point)))
                   beg-add end-add)
               (when (and (diff--forward-while-leading-char ?- end)
                          ;; Allow for "\ No newline at end of file".
                          (progn (diff--forward-while-leading-char ?\\ end)
                                 (setq beg-add (point)))
                          (diff--forward-while-leading-char ?+ end)
                          (progn (diff--forward-while-leading-char ?\\ end)
                                 (setq end-add (point))))
                 (smerge-refine-subst beg-del beg-add beg-add end-add
                                      nil 'diff-refine-preproc props-r props-a)))))
          (`context
           (let* ((middle (save-excursion (re-search-forward "^---")))
                  (other middle))
             (while (re-search-forward "^\\(?:!.*\n\\)+" middle t)
               (smerge-refine-subst (match-beginning 0) (match-end 0)
                                    (save-excursion
                                      (goto-char other)
                                      (re-search-forward "^\\(?:!.*\n\\)+" end)
                                      (setq other (match-end 0))
                                      (match-beginning 0))
                                    other
                                    (if diff-use-changed-face props-c)
                                    'diff-refine-preproc
                                    (unless diff-use-changed-face props-r)
                                    (unless diff-use-changed-face props-a)))))
          (_ ;; Normal diffs.
           (let ((beg1 (1+ (point))))
             (when (re-search-forward "^---.*\n" end t)
               ;; It's a combined add&remove, so there's something to do.
               (smerge-refine-subst beg1 (match-beginning 0)
                                    (match-end 0) end
                                    nil 'diff-refine-preproc props-r props-a)))))))))