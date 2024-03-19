;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; RUN: wasm-opt %s --precompute -all -S -o - | filecheck %s

(module
 ;; CHECK:      (type $array16 (array (mut i16)))
 (type $array16 (array (mut i16)))

 ;; CHECK:      (func $eq-no (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 0)
 ;; CHECK-NEXT: )
 (func $eq-no (result i32)
  (string.eq
   (string.const "ab")
   (string.const "cdefg")
  )
 )

 ;; CHECK:      (func $eq-yes (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 1)
 ;; CHECK-NEXT: )
 (func $eq-yes (result i32)
  (string.eq
   (string.const "ab")
   (string.const "ab")
  )
 )

 ;; CHECK:      (func $concat (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 1)
 ;; CHECK-NEXT: )
 (func $concat (result i32)
  (string.eq
   (string.concat (string.const "a") (string.const "b"))
   (string.const "ab")
  )
 )

 ;; CHECK:      (func $length (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 7)
 ;; CHECK-NEXT: )
 (func $length (result i32)
  (stringview_wtf16.length
   (string.as_wtf16
    (string.const "1234567")
   )
  )
 )

 ;; CHECK:      (func $length-bad (type $0) (result i32)
 ;; CHECK-NEXT:  (stringview_wtf16.length
 ;; CHECK-NEXT:   (string.as_wtf16
 ;; CHECK-NEXT:    (string.const "$_\c2\a3_\e2\82\ac_\f0\90\8d\88")
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $length-bad (result i32)
  ;; Not precomputable because we don't handle unicode yet.
  (stringview_wtf16.length
   (string.as_wtf16
    ;; $_£_€_𐍈
    (string.const "$_\C2\A3_\E2\82\AC_\F0\90\8D\88")
   )
  )
 )

 ;; CHECK:      (func $get_codepoint (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 95)
 ;; CHECK-NEXT: )
 (func $get_codepoint (result i32)
  ;; This is computable because everything up to the requested index is ascii. Returns 95 ('_').
  (stringview_wtf16.get_codeunit
   (string.as_wtf16
    ;; $_£_€_𐍈
    (string.const "$_\C2\A3_\E2\82\AC_\F0\90\8D\88")
   )
   (i32.const 1)
  )
 )

 ;; CHECK:      (func $get_codepoint-bad (type $0) (result i32)
 ;; CHECK-NEXT:  (stringview_wtf16.get_codeunit
 ;; CHECK-NEXT:   (string.as_wtf16
 ;; CHECK-NEXT:    (string.const "$_\c2\a3_\e2\82\ac_\f0\90\8d\88")
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (i32.const 2)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $get_codepoint-bad (export "get_codepoint-bad") (result i32)
  ;; This is not computable because the requested code unit is not ascii.
  (stringview_wtf16.get_codeunit
   (string.as_wtf16
    ;; $_£_€_𐍈
    (string.const "$_\C2\A3_\E2\82\AC_\F0\90\8D\88")
   )
   (i32.const 2)
  )
 )

 ;; CHECK:      (func $encode (type $0) (result i32)
 ;; CHECK-NEXT:  (i32.const 2)
 ;; CHECK-NEXT: )
 (func $encode (result i32)
  (string.encode_wtf16_array
   (string.const "$_")
   (array.new_default $array16
    (i32.const 20)
   )
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $encode-bad (type $0) (result i32)
 ;; CHECK-NEXT:  (string.encode_wtf16_array
 ;; CHECK-NEXT:   (string.const "$_\c2\a3_\e2\82\ac_\f0\90\8d\88")
 ;; CHECK-NEXT:   (array.new_default $array16
 ;; CHECK-NEXT:    (i32.const 20)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (i32.const 0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $encode-bad (result i32)
  (string.encode_wtf16_array
   ;; $_£_€_𐍈
   (string.const "$_\C2\A3_\E2\82\AC_\F0\90\8D\88")
   (array.new_default $array16
    (i32.const 20)
   )
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $slice (type $1) (result (ref string))
 ;; CHECK-NEXT:  (string.const "def")
 ;; CHECK-NEXT: )
 (func $slice (export "slice") (result (ref string))
  ;; Slicing [3:6] here should definitely output "def".
  (stringview_wtf16.slice
   (string.const "abcdefgh")
   (i32.const 3)
   (i32.const 6)
  )
 )

 ;; CHECK:      (func $slice-bad (type $1) (result (ref string))
 ;; CHECK-NEXT:  (stringview_wtf16.slice
 ;; CHECK-NEXT:   (string.const "abcd\c2\a3fgh")
 ;; CHECK-NEXT:   (i32.const 3)
 ;; CHECK-NEXT:   (i32.const 6)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $slice-bad (export "slice-bad") (result (ref string))
  ;; This slice contains non-ascii, so we do not optimize.
  (stringview_wtf16.slice
   ;; abcd£fgh
   (string.const "abcd\C2\A3fgh")
   (i32.const 3)
   (i32.const 6)
  )
 )
)
