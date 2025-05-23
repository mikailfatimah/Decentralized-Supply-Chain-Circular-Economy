;; recycling-verification.clar
;; This contract validates material recovery

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map recycling-records
  { product-id: (string-ascii 36) }
  {
    recycler: principal,
    recycling-date: uint,
    materials-recovered: (list 20 (string-ascii 64)),
    recovery-rates: (list 20 uint),
    verified: bool,
    verifier: (optional principal)
  }
)

;; Events
(define-public (record-recycling
                (product-id (string-ascii 36))
                (materials-recovered (list 20 (string-ascii 64)))
                (recovery-rates (list 20 uint)))
  (let
    ((caller tx-sender))
    (begin
      (asserts! (not (is-some (map-get? recycling-records { product-id: product-id }))) (err u1))
      (asserts! (is-eq (len materials-recovered) (len recovery-rates)) (err u2))
      (map-set recycling-records
        { product-id: product-id }
        {
          recycler: caller,
          recycling-date: block-height,
          materials-recovered: materials-recovered,
          recovery-rates: recovery-rates,
          verified: false,
          verifier: none
        }
      )
      (ok true)
    )
  )
)

(define-public (verify-recycling (product-id (string-ascii 36)))
  (let
    ((record (unwrap! (map-get? recycling-records { product-id: product-id }) (err u3)))
     (caller tx-sender))
    (begin
      (asserts! (not (get verified record)) (err u4))
      (map-set recycling-records
        { product-id: product-id }
        (merge record
          {
            verified: true,
            verifier: (some caller)
          }
        )
      )
      (ok true)
    )
  )
)

(define-read-only (get-recycling-record (product-id (string-ascii 36)))
  (map-get? recycling-records { product-id: product-id })
)

(define-read-only (calculate-total-recovery-rate (product-id (string-ascii 36)))
  (let
    ((record (map-get? recycling-records { product-id: product-id })))
    (if (is-some record)
      (let
        ((rates (get recovery-rates (unwrap-panic record)))
         (total-rate (fold + rates u0)))
        (ok total-rate)
      )
      (err u3)
    )
  )
)
