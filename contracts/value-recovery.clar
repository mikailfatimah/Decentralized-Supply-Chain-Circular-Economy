;; value-recovery.clar
;; This contract tracks economic benefits of circularity

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map value-records
  { product-id: (string-ascii 36) }
  {
    original-value: uint,
    recovered-value: uint,
    circularity-score: uint,
    last-updated: uint
  }
)

;; Events
(define-public (register-product-value (product-id (string-ascii 36)) (original-value uint))
  (let
    ((caller tx-sender))
    (begin
      (asserts! (not (is-some (map-get? value-records { product-id: product-id }))) (err u1))
      (map-set value-records
        { product-id: product-id }
        {
          original-value: original-value,
          recovered-value: u0,
          circularity-score: u0,
          last-updated: block-height
        }
      )
      (ok true)
    )
  )
)

(define-public (update-recovered-value (product-id (string-ascii 36)) (recovered-value uint))
  (let
    ((record (unwrap! (map-get? value-records { product-id: product-id }) (err u2)))
     (caller tx-sender))
    (begin
      (map-set value-records
        { product-id: product-id }
        (merge record
          {
            recovered-value: recovered-value,
            circularity-score: (calculate-circularity-score (get original-value record) recovered-value),
            last-updated: block-height
          }
        )
      )
      (ok true)
    )
  )
)

(define-private (calculate-circularity-score (original uint) (recovered uint))
  (if (is-eq original u0)
    u0
    (/ (* recovered u100) original)
  )
)

(define-read-only (get-value-record (product-id (string-ascii 36)))
  (map-get? value-records { product-id: product-id })
)

(define-read-only (get-circularity-score (product-id (string-ascii 36)))
  (default-to u0 (get circularity-score (map-get? value-records { product-id: product-id })))
)
