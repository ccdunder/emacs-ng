;;; unit tests for src/fileio.c      -*- lexical-binding: t; -*-

;; Copyright 2017 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

(require 'ert)

(defun try-char (char link)
  (let ((target (string char)))
    (make-symbolic-link target link)
    (let* ((read-link (file-symlink-p link))
           (failure (unless (string-equal target read-link)
                      (list 'string-equal target read-link))))
      (delete-file link)
      failure)))

(defun fileio-tests--symlink-failure ()
  (let* ((dir (make-temp-file "fileio" t))
         (link (expand-file-name "link" dir)))
    (unwind-protect
        (let ((failure
               (let ((default-file-name-coding-system 'utf-8-unix))
                 (try-char (unibyte-char-to-multibyte 128) link)))
              (char 0))
          (while (and (not failure) (< char 300))
            (setq char (1+ char))
            (unless (= char ?~)
              (setq failure (try-char char link))))
          failure)
      (delete-directory dir t))))

(ert-deftest fileio-tests--odd-symlink-chars ()
  "Check that any non-NULL ASCII character can appear in a symlink.
Also check that an encoding error can appear in a symlink."
  (should (equal nil (fileio-tests--symlink-failure))))