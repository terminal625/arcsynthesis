;; TODO: about

(in-package #:arc-7)

(defvar *glsl-directory*
  (merge-pathnames #p "7-chapter/" (asdf/system:system-source-directory :arcsynthesis)))
;;todo: fix this output to slime-repl solution
(defvar out *standard-output*)  (defvar dbg *debug-io*) (defvar err *error-output*)

(defvar position-buffer-object) ; buffer object handle


(defvar *program*)

(defparameter *camera-to-clip-matrix* (glm:make-mat4 0.0))
(defparameter *world-to-camera-matrix* (glm:make-mat4 1.0)) ;; identity for now

(defvar *model-to-world-matrix-unif*)
(defvar *world-to-camera-matrix-unif*)
(defvar *camera-to-clip-matrix-unif*)


(defun calc-frustum-scale (f-fov-deg)
  "the field-of-view (fov) is the angle between the forward direction and the direction
of the farmost-extent of the view (meaning vectors from these points still get to hit
the projection plane)"
  (let* ((deg-to-rad (/ (* pi 2.0) 360.0))
	(f-fov-rad (* f-fov-deg deg-to-rad)))
    (coerce
     (/ 1.0
	(tan (/ f-fov-rad 2.0)))
     'single-float)))

;; TODO: why does it look smaller than the screenshots?
;; provisional solution to scale problem using 25.0
(defparameter *frustum-scale* (calc-frustum-scale 25.0)) 

(defun initialize-program ()
  (let ((shader-list (list)))
    ;;oh c'mon how to make it local
    (push (arc:create-shader
	   :vertex-shader
	   (arc:file-to-string
	    (merge-pathnames "pos-color-local-transformation.vert" *glsl-directory*)))
	  shader-list)
    (push (arc:create-shader
    	   :fragment-shader
    	   (arc:file-to-string
	    (merge-pathnames "color-passthrough.frag" *glsl-directory* )))
    	  shader-list)
    (setf *program* (arc:create-program-and-return-it shader-list))

    (setf *model-to-world-matrix-unif*
	  (gl:get-uniform-location *program* "model_to_world_matrix"))
    (setf *world-to-camera-matrix-unif*
	  (gl:get-uniform-location *program* "world_to_camera_matrix"))
    (setf *camera-to-clip-matrix-unif*
	  (gl:get-uniform-location *program* "camera_to_clip_matrix"))

    (format t "mw:~a wc:~a cc:~a"
	    *model-to-world-matrix-unif*
	    *world-to-camera-matrix-unif*
	    *camera-to-clip-matrix-unif*)

    (let ((fz-near 1.0)
	  (fz-far 45.0))
      (glm:set-mat4 *camera-to-clip-matrix* 0 :x *frustum-scale*)
      (glm:set-mat4 *camera-to-clip-matrix* 1 :y *frustum-scale*)
      (glm:set-mat4 *camera-to-clip-matrix* 2 :z (/ (+ fz-far fz-near)
						    (- fz-near fz-far)))
      (glm:set-mat4 *camera-to-clip-matrix* 2 :w -1.0)
      (glm:set-mat4 *camera-to-clip-matrix* 3 :z (/ (* 2 fz-far fz-near)
						    (- fz-near fz-far)))
      (%gl:use-program *program*)

      (gl:uniform-matrix *camera-to-clip-matrix-unif* 4 (vector *camera-to-clip-matrix*)
			 :false))
    (%gl:use-program 0)
    (loop for shader-object in shader-list
       do (%gl:delete-shader shader-object))))


(defparameter *number-of-vertices* 4) ;; TODO: maybe 3, if counting from 0

(defparameter +red-color+   '(1.0 0.0 0.0 1.0))
(defparameter +green-color+ '(0.0 1.0 0.0 1.0))
(defparameter +blue-color+  '(0.0 0.0 1.0 1.0))

(defparameter +yellow-color+ '(1.0 1.0 0.0 1.0))
(defparameter +cyan-color+ '(0.0 1.0 1.0 1.0))
(defparameter +magenta-color+ '(1.0 0.0 1.0 1.0))


(defparameter *vertex-data*
  (arc:create-gl-array-from-vector 
`#(

	;; vertex positions
	+1.0  +1.0  +1.0 
	+1.0  -1.0  +1.0 
	-1.0  -1.0  +1.0 
	-1.0  +1.0  +1.0 

        ;; vertex colors
	,@+green-color+
	,@+green-color+
	,@+green-color+
	,@+green-color+
  )))

(defparameter *index-data*
  (arc::create-gl-array-of-unsigned-short-from-vector
   #(
	0  1  2 
        0  2  3

	4  5  6 
	6  7  4 
     )))

(defvar *vertex-buffer-object*)
(defvar *index-buffer-object*)

(defun initialize-vertex-buffer ()
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

(defvar *vao*)

(defun initialize-vertex-array-objects ()
  (setf *vao* (first (gl:gen-vertex-arrays 1)))
  (gl:bind-vertex-array *vao*)

  (let ((color-data-offset (* #|size-of(float):|# 4 3 *number-of-vertices*)))
    (gl:bind-buffer :array-buffer *vertex-buffer-object*)
    (%gl:enable-vertex-attrib-array 0)
    (%gl:enable-vertex-attrib-array 1)
    (%gl:vertex-attrib-pointer 0 3 :float :false 0 0)
    (%gl:vertex-attrib-pointer 1 4 :float :false 0 color-data-offset)
    (%gl:bind-buffer :element-array-buffer *index-buffer-object*)

    (%gl:bind-vertex-array 0)
    )
  )




(defun init ()
	(initialize-program)
	(initialize-vertex-buffer)
	(initialize-vertex-array-objects)
  
	(gl:enable :cull-face)
	(%gl:cull-face :back)
	(%gl:front-face :cw) ;; TODO maybe bad order vertices, need to change; test here

	(gl:viewport 0 0 500 500)

	(gl:enable :depth-test)
	(gl:depth-mask :true)
	(%gl:depth-func :lequal)
	(gl:depth-range 0.0 1.0)
)

(defun draw ()
  (%gl:draw-elements :triangles (gl::gl-array-size *index-data*)
		    :unsigned-short 0)
  )

;; makeshift solution
(defparameter t-mat (let ((translate-mat4 (glm:make-mat4 1.0))
			 (vec4 (glm:vec4-from-vec3 (glm:vec3 3.0 -5.0 -40.0))))
		     (glm:set-mat4-col translate-mat4 3 vec4)
		     translate-mat4))
;;NEXT TODO: fully functional with-transform operating on matrix-stacks
;;then scale that rectangle and work on the worl to camera translation, then
;;make the camera focus each corner on command, then move towards dynamic camera,
;;then really try to copy the tutorial implementing the trees with multiple shaders
;;and the parthenon
(defvar *model-to-camera-ms*)

(defun model-to-world-setup ()
  (setf *model-to-camera-ms* (make-instance 'glutil:matrix-stack))
  (glutil:with-transform (*model-to-camera-ms*)
    :translate 3.0 -5.0 -40.0
    :scale 5.0 5.0 5.0
    :rotate-z 75.0
    ;;well this is too verbose?
    (glutil::matrix-stack-top-to-shader-and-draw *model-to-camera-ms*
						 *model-to-world-matrix-unif*
						 *index-data*))

  )

(defun display ()
  (gl:clear-color 0 0 0.2 1)
  (gl:clear-depth 1.0)
  (gl:clear :color-buffer-bit :depth-buffer-bit)

  (%gl:use-program *program*)
  (gl:bind-vertex-array *vao*)

  (model-to-world-setup)
  (draw)
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
	(init)
	(sdl2:with-event-loop (:method :poll)
	  (:keydown
	   (:keysym keysym)
	   ;; TODO: capture in macro
	   ;; AdjBase()
	   (when (sdl2:scancode= (sdl2:scancode-value keysym) :scancode-e)
	     (print "e key pressed!"))
	   

	   (when (sdl2:scancode= (sdl2:scancode-value keysym) :scancode-escape)
	     (sdl2:push-event :quit)))
	  (:quit () t)
	  (:idle ()
		 ;;main-loop:
		 (display)
		 
                 (sdl2:gl-swap-window win) ; wow, this can be forgotten easily -.-
		 ))))))

