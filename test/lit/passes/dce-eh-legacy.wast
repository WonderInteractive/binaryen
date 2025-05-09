;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: wasm-opt %s --dce -all -S -o - | filecheck %s

;; If either try body or catch body is reachable, the whole try construct is
;; reachable
(module
  ;; CHECK:      (type $0 (func))

  ;; CHECK:      (type $1 (func (param i32)))

  ;; CHECK:      (type $2 (func (param eqref)))

  ;; CHECK:      (type $3 (func (param i32 i32)))

  ;; CHECK:      (type $4 (func (result i32)))

  ;; CHECK:      (type $struct (struct (field (mut eqref))))
  (type $struct (struct (field (mut (ref null eq)))))

  ;; CHECK:      (tag $e (type $0))
  (tag $e)
  ;; CHECK:      (tag $e-i32 (type $1) (param i32))
  (tag $e-i32 (param i32))
  ;; CHECK:      (tag $e-eqref (type $2) (param eqref))
  (tag $e-eqref (param (ref null eq)))

  ;; CHECK:      (func $foo (type $0)
  ;; CHECK-NEXT: )
  (func $foo)

  ;; CHECK:      (func $try_unreachable (type $0)
  ;; CHECK-NEXT:  (try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $foo)
  ;; CHECK-NEXT: )
  (func $try_unreachable
    (try
      (do
        (unreachable)
      )
      (catch_all)
    )
    (call $foo) ;; shouldn't be dce'd
  )

  ;; CHECK:      (func $catch_unreachable (type $0)
  ;; CHECK-NEXT:  (try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $foo)
  ;; CHECK-NEXT: )
  (func $catch_unreachable
    (try
      (do)
      (catch_all
        (unreachable)
      )
    )
    (call $foo) ;; shouldn't be dce'd
  )

  ;; CHECK:      (func $both_unreachable (type $0)
  ;; CHECK-NEXT:  (try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $both_unreachable
    (try
      (do
        (unreachable)
      )
      (catch_all
        (unreachable)
      )
    )
    (call $foo) ;; should be dce'd
  )

  ;; CHECK:      (func $rethrow (type $0)
  ;; CHECK-NEXT:  (try $l0
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch $e
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.const 0)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (rethrow $l0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $rethrow
    (try $l0
      (do)
      (catch $e
        (drop
          ;; This i32.add will be dce'd
          (i32.add
            (i32.const 0)
            (rethrow $l0)
          )
        )
      )
    )
  )

  ;; CHECK:      (func $call-pop-catch (type $0)
  ;; CHECK-NEXT:  (local $0 i32)
  ;; CHECK-NEXT:  (block $label
  ;; CHECK-NEXT:   (try
  ;; CHECK-NEXT:    (do
  ;; CHECK-NEXT:     (nop)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (catch $e-i32
  ;; CHECK-NEXT:     (local.set $0
  ;; CHECK-NEXT:      (pop i32)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (block
  ;; CHECK-NEXT:      (block
  ;; CHECK-NEXT:       (drop
  ;; CHECK-NEXT:        (local.get $0)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (br $label)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-pop-catch
    (block $label
     (try
       (do
         (nop)
       )
       (catch $e-i32
         ;; This call is unreachable and can be removed. The pop, however, must
         ;; be carefully handled while we do so, to not break validation.
         (call $helper-i32-i32
           (pop i32)
           (br $label)
         )
         (nop)
       )
      )
    )
  )

  ;; CHECK:      (func $helper-i32-i32 (type $3) (param $0 i32) (param $1 i32)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $helper-i32-i32 (param $0 i32) (param $1 i32)
   (nop)
  )

  ;; CHECK:      (func $pop-within-block (type $4) (result i32)
  ;; CHECK-NEXT:  (local $0 eqref)
  ;; CHECK-NEXT:  (try (result i32)
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (i32.const 0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch $e-eqref
  ;; CHECK-NEXT:    (local.set $0
  ;; CHECK-NEXT:     (pop eqref)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (block
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (struct.new $struct
  ;; CHECK-NEXT:        (local.get $0)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (unreachable)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $pop-within-block (result i32)
    (try (result i32)
      (do
        (i32.const 0)
      )
      (catch $e-eqref
        (drop
          ;; Optimization moves the 'pop' inside a block, which needs to be
          ;; extracted out of the block at the end.
          ;; (block
          ;;   (drop
          ;;     (struct.new $struct.0
          ;;       (pop eqref)
          ;;     )
          ;;   )
          ;;   (unreachable)
          ;; )
          (ref.eq
            (struct.new $struct
              (pop (ref null eq))
            )
            (unreachable)
          )
        )
        (i32.const 0)
      )
    )
  )
)

