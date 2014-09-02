(in-package #:arc-5)

(defvar *glsl-directory*
  (merge-pathnames #p "5-chapter/" (asdf/system:system-source-directory :arcsynthesis)))
;;TODO: what with this garbage here >_>, or should I really build the habit of looking
;; at the terminal
(defvar out *standard-output*)  (defvar dbg *debug-io*) (defvar err *error-output*)

(defparameter *verts* NIL)

(defparameter *vertex-positions* nil)

;(setf *vertex-positions* (arc::create-gl-array-from-vector *verts*))

(defparameter position-buffer-object nil) ; buffer object handle
(defparameter x-offset 0) (defparameter y-offset 0)
(defparameter *program* nil "program-object")
(defparameter *offset-uniform* 0)
(defparameter z-near-uniform 0)
(defparameter z-far-uniform 0)
(defparameter frustum-scale-uniform 0)

(defparameter matrix-uniform nil)
(defparameter perspective-matrix nil)

(defparameter frustum-scale 0)

(defun initialize-program ()
  (let ((shader-list (list)))
    ;;oh c'mon how to make it local
    (push (arc:create-shader
	   :vertex-shader
	   (arc:file-to-string
	    (merge-pathnames "vs-ch5.glsl" *glsl-directory*)))
	  shader-list)
    (push (arc:create-shader
    	   :fragment-shader
    	   (arc:file-to-string (merge-pathnames "fs.glsl" *glsl-directory* )))
    	  shader-list)
    (setf *program* (arc:create-program-and-return-it shader-list))
    (let ((s 1.0) (n 0.5) (f 3.0)	;frustum-scale, zNear, zFar
	  )
      (setf matrix-uniform (gl:get-uniform-location *program* "perspective_matrix"))
      (setf perspective-matrix
	    (make-array 16 :element-type 'single-float
			:initial-contents
			;; the matrix with its coefficients 'switches' and the perma 
			;; "on-switch" the 'w' component
			(list s 0.0 0.0 0.0                                     ;= x
			      0.0 s 0.0 0.0                                     ;= y
			      0.0 0.0 (/ (+ f n) (- n f)) (/ (* 2 f n) (- n f)) ;= z
			      0.0 0.0 -1.0 0.0)))                               ;= w

      (setf *offset-uniform* (gl:get-uniform-location *program* "offset"))
      (%gl:use-program *program*)
      (format t "off-u:~a mat-u:~a" *offset-uniform* matrix-uniform)

      (gl:uniform-matrix matrix-uniform 4 (vector perspective-matrix) :false))
    (loop for shader-object in shader-list
       do (%gl:delete-shader shader-object))))


(defparameter *vao-object-1* nil)
(defparameter *vao-object-2* nil)

(defparameter *number-of-vertices* 36)
(defparameter *vertex-buffer-object* nil)

(defparameter *vertex-data*
  ;; TODO fill this with arcsynthesi' data >,<
  (arc:create-gl-array-from-vector 
#(
  ;; note, as arcsynthesis states itself, our position are 3-dimensional, but
  ;; the shaders takes a vec4. if a value is not provided it is defaulted to 0.0
  ;; except for the 'w' value, which defaults to 1.0! So nice way to save space!
 -0.8  0.2  -1.75
 -0.8  0.0  -1.25
  0.8  0.0  -1.25
  0.8  0.2  -1.75

 -0.8 -0.2 -1.75
 -0.8 0.0 -1.25
 0.8 0.0 -1.25
 0.8 -0.2 -1.75

 -0.8 0.2 -1.75
 -0.8 0.0 -1.25
 -0.8 -0.2 -1.75

 0.8 0.2 -1.75
 0.8 0.0 -1.25
 0.8 -0.2 -1.75

 -0.8 -0.2 -1.75
 -0.8 0.2 -1.75
 0.8 0.2 -1.75
 0.8 -0.2 -1.75

 ;;Object 2 positions
 0.2 0.8 -1.75
 0.0 0.8 -1.25
 0.0 -0.8 -1.25
 0.2 -0.8 -1.75

 -0.2 0.8 -1.75
 0.0 0.8 -1.25
 0.0 -0.8 -1.25
 -0.2 -0.8 -1.75

 0.2 0.8 -1.75
 0.0 0.8 -1.25
 -0.2 0.8 -1.75

 0.2 -0.8 -1.75
 0.0 -0.8 -1.25
 -0.2 -0.8 -1.75

 -0.2 0.8 -1.75
 0.2 0.8 -1.75
 0.2 -0.8 -1.75
 -0.2 -0.8 -1.75

 ;;Object 1 colors
 0.75 0.75 1.0 1.0 
 0.75 0.75 1.0 1.0 
 0.75 0.75 1.0 1.0 
 0.75 0.75 1.0 1.0 

 0.0 0.5 0.0 1.0 
 0.0 0.5 0.0 1.0 
 0.0 0.5 0.0 1.0 
 0.0 0.5 0.0 1.0 

 1.0 0.0 0.0 1.0 
 1.0 0.0 0.0 1.0 
 1.0 0.0 0.0 1.0 

 0.8 0.8 0.8 1.0 
 0.8 0.8 0.8 1.0 
 0.8 0.8 0.8 1.0 
  
 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 

 ;;Object 2 colors
 1.0 0.0 0.0 1.0 
 1.0 0.0 0.0 1.0 
 1.0 0.0 0.0 1.0 
 1.0 0.0 0.0 1.0 

 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 
 0.5 0.5 0.0 1.0 

 0.0 0.5 0.0 1.0 
 0.0 0.5 0.0 1.0 
 0.0 0.5 0.0 1.0 

 0.75 0.75 1.0 1.0 
 0.75 0.75 1.0 1.0 
 0.75 0.75 1.0 1.0 

 0.8 0.8 0.8 1.0 
 0.8 0.8 0.8 1.0 
 0.8 0.8 0.8 1.0 
 0.8 0.8 0.8 1.0 

  )))

(defparameter *index-buffer-object* nil)
(defparameter *index-data*
  ;; this makes sure that *index-data* is of type unsigned-short
  ;; which is important to have (gl:draw-elements ...) working!
  (arc::create-gl-array-of-unsigned-short-from-vector #(
;;two faces in the front
 0  2  1
 3  2  0

 4  5  6 
 6  7  4 
;;two faces from behind?
 8  9 10 
11 13 12 

14 16 15 
17 16 14
							
)))

(defun initialize-vertex-buffer ()
  ;; create and allocate buffers to OpenGL context -object* expose the handle
  ;; to those allocated data!
  ;; VAO-buffer time
  (setf *vertex-buffer-object* (first (gl:gen-buffers 1)))

  (gl:bind-buffer :array-buffer *vertex-buffer-object*)
  (gl:buffer-data :array-buffer :static-draw *vertex-data*)
  (gl:bind-buffer :array-buffer 0)

  ;; index-array time:
  (setf *index-buffer-object* (first (gl:gen-buffers 1)))

  (gl:bind-buffer :element-array-buffer  *index-buffer-object*)
  (gl:buffer-data :element-array-buffer  :static-draw *index-data*)
  (gl:bind-buffer :element-array-buffer  0)  
  )

(defun initialize-vertex-array-objects ()
  ;; the *vertex-buffer-object* is just a handle to some vertex data stored via
  ;; the :array-buffer and gl:buffer-data calls
  ;; but *vao-object-1* is the drawing data containing object! It contains data
  ;; about the vertex attribute their format and what :element-array-buffer is used
  ;; to iterate through them (in what order the shader will use them)!!!

  (setf *vao-object-1* (first (gl:gen-vertex-arrays 1)))
  (gl:bind-vertex-array *vao-object-1*)

  (let ((color-data-offset (* #|size-of(float):|# 4 3 *number-of-vertices*))
	(pos-data-offset (* #|size-of(float):|# 4 3 (/ *number-of-vertices* 2))))
    (gl:bind-buffer :array-buffer *vertex-buffer-object*)
    ;; this is very important to understand: the following functions
    ;; change the state of the *vao-object-1*! This *vao-object-1* after these 5 functions
    ;; will contain information: where the attribute index start, how many consist of
    ;; a vertex etc. and finally in what order they should be read: this is what
    ;; (bind-buffer :element-array-buffer *index-buffer-object*) superimposes!!!
    (%gl:enable-vertex-attrib-array 0)
    (%gl:enable-vertex-attrib-array 1)
    (%gl:vertex-attrib-pointer 0 3 :float :false 0 0)
    (%gl:vertex-attrib-pointer 1 4 :float :false 0 color-data-offset)
    (%gl:bind-buffer :element-array-buffer *index-buffer-object*)

    (%gl:bind-vertex-array 0)

    (setf *vao-object-2* (first (gl:gen-vertex-arrays 1)))
    (%gl:bind-vertex-array *vao-object-2*) ; look! we bind it directly - without a target!
     
    (incf color-data-offset
	  (* #|size-of(float):|# 4 4 (/ *number-of-vertices* 2)))

    ;; note how we implicitly use the same :array-buffer as *vao-object-1* !!!
    ;; This is solved by (gl:vertex-attrib-pointer ..) which takes the current buffer
    ;; bound to :array-buffer and associates it with the given vertex attributes
    ;; :array-buffer is to be understood as a 'global-pointer' from which
    ;; gl:vertex-attrib-pointer reads. But once it is done reading it doesn't matter
    ;; what is bound to :array-buffer after that!!! :array-buffer is still crucial
    ;; in the initialization of VAO objects!!
    (%gl:enable-vertex-attrib-array 0)
    (%gl:enable-vertex-attrib-array 1)
    (%gl:vertex-attrib-pointer 0 3 :float :false 0 pos-data-offset) ;reads :array-buffer
    (%gl:vertex-attrib-pointer 1 4 :float :false 0 color-data-offset) ;implicitly!!!!!
    (%gl:bind-buffer :element-array-buffer *index-buffer-object*)

    (%gl:bind-vertex-array 0)

    )
  )


(defun rendering-code ()
  (gl:clear-color 0 0 0.2 1)
  (gl:clear :color-buffer-bit)

  (%gl:use-program *program*)

  (gl:bind-vertex-array *vao-object-1*)
  (%gl:uniform-3f *offset-uniform* 0.0 0.0 0.0)
  ;; From cl-opengl examples:
  ;; The vertex data comes from the currently-bound VAO, *vao-object-2*, if the input
  ;; array is null, (gl:make-NULL-gl-array :unsigned-short), the indices will be taken
  ;; from the element array buffer bound in the current VAO
  ;; look out, the last parameter /indices/ is a misnomer, it is just the offset at which
  ;; the index data starts it should be called: index-offset
  ;; (gl:draw-elements :triangles (gl:make-null-gl-array :unsigned-short) :count
  ;;		    (gl::gl-array-size *index-data*))

  ;; But, alas, it is longer then the direct translation:
  (%gl:draw-elements :triangles (gl::gl-array-size *index-data*) :unsigned-short 0)
  
  (gl:bind-vertex-array *vao-object-2*)
  ;; uniform changing calls don't are independent of the currently bound vertex-object
  (%gl:uniform-3f *offset-uniform* 0.0 0.0 -1.0)

  (gl:draw-elements :triangles (gl:make-null-gl-array :unsigned-short)
		    :count (gl::gl-array-size *index-data*))

  (gl:bind-vertex-array 0)
  (gl:use-program *program*)
    
  ;;swap buffers: in main loop 
  )

(defun main ()
  (sdl2:with-init (:everything)
    (progn (setf *standard-output* out) (setf *debug-io* dbg) (setf *error-output* err))
    (sdl2:with-window (win :w 500 :h 500 :flags '(:shown :opengl :resizable))
      (sdl2:with-gl-context (gl-context win)
	;; INIT code:
	(initialize-program)
	(initialize-vertex-buffer)
	(initialize-vertex-array-objects)
  
	(gl:enable :cull-face)
	(%gl:cull-face :back)
	(%gl:front-face :cw)
	(gl:viewport 0 0 500 500)

	(sdl2:with-event-loop (:method :poll)
	  (:keyup
	   (:keysym keysym)
	   (when (sdl2:scancode= (sdl2:scancode-value keysym) :scancode-e)
	     ;; experimental code
	     )
	   (when (sdl2:scancode= (sdl2:scancode-value keysym) :scancode-escape)
	     (sdl2:push-event :quit)))
	  (:quit () t)
	  (:idle ()
		 ;;main-loop:
		 (rendering-code)
		 
                 (sdl2:gl-swap-window win) ; wow, this can be forgotten easily -.-
		 ))))))