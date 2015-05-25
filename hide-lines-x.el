;;; hide-lines-x.el --- Commands for hiding lines based on a regexp

;; Filename: hide-lines-x.el
;; Description: Commands for hiding lines based on a regexp. Based on hide-lines.el by Mark Hulme-Jones <ture at plig cucumber dot net>
;; Author : Andrew Sichevoi (http://thekondor.net)
;; Version: 20150525
;; Keywords: convenience buffer filter
;; URL: https://github.com/thekondor/hide-lines-x
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires:  
;;
;; Features that might be required by this library:
;;
;; 
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;; Author of hide-lines.x: Mark Hulme-Jones <ture at plig cucumber dot net>

;;; Commentary
;; 
;; The simplest way to make hide-lines-x work is to add the following
;; lines to your .emacs file:
;; 
;; (autoload 'hide-lines-x "hide-lines-x" "Hide lines based on a regexp" t)
;; (global-set-key (kbd "C-c /") 'hide-lines-x)
;; 
;; Now, when you type C-c /, you will be prompted for a regexp
;; (regular expression).  All lines matching this regexp will be
;; hidden in the buffer.
;; 
;; Alternatively, you can type C-u C-c / (ie. provide a prefix
;; argument to the hide-lines-x command) to hide all lines that *do not*
;; match the specified regexp. If you want to reveal previously hidden
;; lines you can use any other prefix, e.g. C-u C-u C-c /
;; 

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `hide-lines-x'
;;    Hide lines matching the specified regexp.
;;  `hide-lines-x-not-matching'
;;    Hide lines that don't match the specified regexp.
;;  `hide-lines-x-not-matching-dwim'
;;    An extended version of `hide-lines-x-not-matching' with DWIM semantics. Uses active region or symbol as a regexp w/o user prompt.
;;    A supplied universal argument allows to edit DWIM regexp before applying.
;;  `hide-lines-x-matching'
;;    Hide lines matching the specified regexp.
;;  `hide-lines-x-matching-dwim'
;;    An extended version of `hide-lines-x-matching' with DWIM semantics. Uses active region or symbol as a regexp w/o user prompt.
;;    A supplied universal argument allows to edit DWIM regexp before applying.
;;  `hide-lines-x-show-all'
;;    Show in the current buffer all areas hidden by the filter-buffer command.
;;    A supplied universal arguments applies the operation to all buffers.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `hide-lines-x-reverse-prefix'
;;    If non-nil then `hide-lines-x' will call `hide-lines-x-matching' by default, and `hide-lines-x-not-matching' with a single prefix.
;;    default = nil. This variable is buffer local so you can use different values for different buffers.

;;; Installation:
;;
;; Put hide-lines-x.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'hide-lines-x)

;;; Change log:
;;
;; 2015/05/25 - Add: `hide-lines-x-not-matching-dwim' and `hide-lines-x-matching-dwim' functions.
;;
;; 2015/05/21 - Change: `hide-lines-x-show-all' removes filter from the current buffer by default. An universal argument must be provided to apply the operation to all buffers.
;;
;; 2015/05/20 - Initial fork of `hide-lines.el'.

;;; TODO
;;
;; 
;;

;;; Require
(require 'cl)


;;; Code:

(defgroup hide-lines-x nil
  "Commands for hiding lines based on a regexp.")

(defvar hide-lines-x-invisible-areas ()
 "List of invisible overlays used by hidelines")

(defcustom hide-lines-x-reverse-prefix nil
  "If non-nil then `hide-lines-x' will call `hide-lines-x-matching' by default, and `hide-lines-x-not-matching' with a single prefix.
Otherwise it's the other way round.
In either case a prefix arg with any value apart from 1 or 4 will call `hide-lines-x-show-all'."
  :type 'boolean
  :group 'hide-lines-x)

(make-variable-buffer-local 'hide-lines-x-reverse-prefix)

(add-to-invisibility-spec 'hl)

;;;###autoload
(defun hide-lines-x (&optional arg)
  "Hide lines matching the specified regexp.
With prefix arg of 4 (C-u) hide lines that do not match the specified regexp.
With any other prefix arg, reveal all hidden lines."
  (interactive "p")
  (cond ((= arg 4) (call-interactively
                    (if hide-lines-x-reverse-prefix 'hide-lines-x-matching
                      'hide-lines-x-not-matching)))
        ((= arg 1) (call-interactively
                    (if hide-lines-x-reverse-prefix 'hide-lines-x-not-matching
                      'hide-lines-x-matching)))
        (t (call-interactively 'hide-lines-x-show-all))))

(defun hide-lines-x-add-overlay (start end)
  "Add an overlay from `start' to `end' in the current buffer.  Push the
overlay onto the hide-lines-x-invisible-areas list"
  (let ((overlay (make-overlay start end)))
    (setq hide-lines-x-invisible-areas (cons overlay hide-lines-x-invisible-areas))
    (overlay-put overlay 'invisible 'hl)))

(defun hide-lines-x-get-overlays (&optional buffer)
  "Get overlays created for the specified `buffer'. If not specified overlays for all buffers are returned."
  (let ((predicate (if buffer
		       (lambda (overlay)
			 (eq buffer (overlay-buffer overlay)))
		     (lambda (overlay) t))))
    (remove-if-not predicate hide-lines-x-invisible-areas)))
  
(defun hide-lines-x-delete-overlays (&optional buffer)
  "Delete overlays created for the specified `buffer'. If not set overlays for all buffers are deleted."
  (let ((overlays (hide-lines-x-get-overlays buffer)))
    (mapc #'delete-overlay overlays)
    (setq hide-lines-x-invisible-areas (set-difference hide-lines-x-invisible-areas overlays))
    overlays))

(defun hide-lines-x-delete-overlays-current-buffer ()
  "A shortcut for `hide-lines-x-delete-overlays' command with bound `current-buffer' as argument."
  (hide-lines-x-delete-overlays (current-buffer)))

(defun hide-lines-x-dwim-value ()
  "Get meant value. Could be active region or symbol at point."
  (cond ((use-region-p) (buffer-substring-no-properties (region-beginning) (region-end)))
	((symbol-at-point) (symbol-name (symbol-at-point)))))

(defun hide-lines-x-dwim-get-search-text (&optional with-correction)
  "Get meant search text. The text could be corrected if `with-correction' argument is set."
  (let* ((initial-needle (hide-lines-x-dwim-value))
	 (approved-needle (cond
			   ((or with-correction (not initial-needle)) (read-string "Correct: " initial-needle))
			   (t initial-needle))))
    approved-needle))

;;;###autoload
(defun hide-lines-x-not-matching (search-text)
  "Hide lines that don't match the specified regexp."
  (interactive "MHide lines not matched by regexp: ")
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion 
    (goto-char (point-min))
    (let ((start-position (point-min))
          (pos (re-search-forward search-text nil t)))
      (while pos
        (beginning-of-line)
        (hide-lines-x-add-overlay start-position (point))
        (forward-line 1)
        (setq start-position (point))
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward search-text nil t))))
      (hide-lines-x-add-overlay start-position (point-max)))))

;;;###autoload
(defun hide-lines-x-not-matching-dwim (&optional with-correction)
  "An extended version of `hide-lines-x-not-matching'. The search text is taken from active region or symbol at point. Optional `with-correction' argument allows to edit choosen search text."
  (interactive "P")
  (let ((search-text (hide-lines-x-dwim-get-search-text with-correction)))
    (cond (search-text (hide-lines-x-not-matching search-text))
	  (t (call-interactively 'hide-lines-x-not-matching)))))

;;;###autoload
(defun hide-lines-x-matching-dwim (&optional with-correction)
  "An extended version of `hide-lines-x-matching'. The search text is taken from active region or symbol at point. Optional `with-correction' argument allows to edit choosen search text."
  (interactive "P")
  (let ((search-text (hide-lines-x-dwim-get-search-text with-correction)))
    (cond (search-text (hide-lines-x-matching search-text))
	  (t (call-interactively 'hide-lines-x-matching)))))

;;;###autoload
(defun hide-lines-x-matching  (search-text)
  "Hide lines matching the specified regexp."
  (interactive "MHide lines matching regexp: ")
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion
    (goto-char (point-min))
    (let ((pos (re-search-forward search-text nil t))
          start-position)
      (while pos
        (beginning-of-line)
        (setq start-position (point))
        (end-of-line)
        (hide-lines-x-add-overlay start-position (+ 1 (point)))
        (forward-line 1)
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward search-text nil t)))))))

;;;###autoload
(defun hide-lines-x-show-all ()
  "Show all areas hidden by the `hide-lines-x-*-matching' command. If universal argument is specified, the command is applied for all buffers."
  (interactive)
  (hide-lines-x-delete-overlays (if current-prefix-arg nil
				  (current-buffer))))

;;;###autoload
(add-hook 'kill-buffer-hook 'hide-lines-x-delete-overlays-current-buffer)

(provide 'hide-lines-x)

;;; hide-lines-x.el ends here
