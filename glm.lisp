;; This code tries to emulate the GLM-library
;; TODO: readermacro? *matrix*0.x => (mat4-place *matrix* 0 :x)

(in-package #:glm)

;;first a simple solution
(defun make-mat4 (init-diagonal-values)
  (let ((idv init-diagonal-values))	;bad style?
    (make-array 16 :element-type 'single-float
		:initial-contents
		(list idv 0.0 0.0 0.0              
		      0.0 idv 0.0 0.0    
		      0.0 0.0 idv 0.0
		      0.0 0.0 0.0 idv))))

;; so as to be used in conjunction with SETF
;; TODO: maybe SETF facilitates this somehow already? some DEFMETHOD?
(defmacro mat4-place (mat4 col coordinate)
  (let ((c (ecase coordinate
	    (:x 0) (:y 1) (:z 2) (:w 3))))
    `(aref ,mat4 ,(+ (* 4 col)  c))))

(defmacro set-mat4 (mat4 row coordinate set-value)
  `(setf (mat4-place ,mat4 ,row ,coordinate) ,set-value))


;; this can't work as a macro, because a macro can't have runtime
;; specific information. It can't know the length of the <vector>
;; given because it is created at runtime (example: (init-g-instance-list)
;;
;; TODO: shouldn't try to implement glm, as it seems to get most of its
;; features from function overloading. Abandon this approach altogether?
;; (defun set-mat4-row-any-vec (mat4 row vector)
;;   (let ((key (ecase row
;; 	       (0 :x) (1 :y) (2 :z) (3 :w))))
;;     (loop for vector-element across vector
;;        for j = 0 then (1+ j)
;;        do
;; 	 `(setf (mat4-place ,mat4 j ,key) vector-element)
;; 	 )))

(defmacro set-mat4-row (mat4 row vec4)
  (let ((key (ecase row
	       (0 :x) (1 :y) (2 :z) (3 :w))))
    `(progn (setf (mat4-place ,mat4 0 ,key) (aref ,vec4 0))
	    (setf (mat4-place ,mat4 1 ,key) (aref ,vec4 1))
	    (setf (mat4-place ,mat4 2 ,key) (aref ,vec4 2))
	    (setf (mat4-place ,mat4 3 ,key) (aref ,vec4 3))))
  )

;; TODO: (set-mat4-row *m* 3 #(1.0 2.0 3.0)) doesn't work: #(..) has to be (vector ..)
;; why?
(defmacro set-mat4-col (mat4 col vec4)
  `(progn (setf (mat4-place ,mat4 ,col :x) (aref ,vec4 0))
	  (setf (mat4-place ,mat4 ,col :y) (aref ,vec4 1))
	  (setf (mat4-place ,mat4 ,col :z) (aref ,vec4 2))
	  (setf (mat4-place ,mat4 ,col :w) (aref ,vec4 3)))
  )

(defun vec3 (x y z)
  (let ((x (float x))
	(y (float y))
	(z (float z)))
    (make-array 3 :element-type 'single-float
		:initial-contents (list x y z))))

(defun vec4-from-vec3 (vec3)
  "Fills vec4 with vec3 ending in w:1.0!"
  (let ((x (aref vec3 0))
	(y (aref vec3 1))
	(z (aref vec3 2)))
    (make-array 4 :element-type 'single-float
		:initial-contents (list x y z 1.0))))

;; TODO: experiment later using a class :I, maybe just use it to have a neat
;; print representation of the array (new-line every 4 values)?
(defclass mat4 ()
  ((mat4 :initarg :mat4-contents
	 :accessor get-matrix)))




(defun create-mat4 (init-diagonal-values)
  (let ((idv init-diagonal-values))	;bad style?
    (make-instance 'mat4 :mat4-contents
		   (make-array 16 :element-type 'single-float
			       :initial-contents
			       (list idv 0.0 0.0 0.0              
				     0.0 idv 0.0 0.0    
				     0.0 0.0 idv 0.0
				     0.0 0.0 0.0 idv)))))


(defmethod print-object ((matrix mat4) stream)
  (print-unreadable-object (matrix stream :type 'single-float :identity t)
    (format stream "~A" (get-matrix matrix))))