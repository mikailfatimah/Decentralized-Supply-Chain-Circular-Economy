;; end-of-life-tracking.clar
;; This contract monitors product disposal

(define-data-var contract-owner principal tx-sender)

;; Define disposal methods
(define-constant DISPOSAL_RECYCLE u1)
(define-constant DISPOSAL_REUSE u2)
(define-constant DISPOSAL_LANDFILL u3)

;; Data structures
(define-map product-lifecycle
  { product-id: (string-ascii 36) }
  {
    end-of-life: bool,
    disposal-method: (optional uint),
    disposal-date: (optional uint),
    disposal-location: (optional (string-ascii 64)),
    disposed-by: (optional principal)
  }
)

;; Events
(define-public (register-product-lifecycle (product-id (string-ascii 36)))
  (let
    ((caller tx-sender))
    (begin
      (asserts! (not (is-some (map-get? product-lifecycle { product-id: product-id }))) (err u1))
      (map-set product-lifecycle
        { product-id: product-id }
        {
          end-of-life: false,
          disposal-method: none,
          disposal-date: none,
          disposal-location: none,
          disposed-by: none
        }
      )
      (ok true)
    )
  )
)

(define-public (mark-end-of-life
                (product-id (string-ascii 36))
                (disposal-method uint)
                (disposal-location (string-ascii 64)))
  (let
    ((lifecycle (unwrap! (map-get? product-lifecycle { product-id: product-id }) (err u2)))
     (caller tx-sender))
    (begin
      (asserts! (not (get end-of-life lifecycle)) (err u3))
      (asserts! (or (is-eq disposal-method DISPOSAL_RECYCLE)
                   (is-eq disposal-method DISPOSAL_REUSE)
                   (is-eq disposal-method DISPOSAL_LANDFILL)) (err u4))
      (map-set product-lifecycle
        { product-id: product-id }
        {
          end-of-life: true,
          disposal-method: (some disposal-method),
          disposal-date: (some block-height),
          disposal-location: (some disposal-location),
          disposed-by: (some caller)
        }
      )
      (ok true)
    )
  )
)

(define-read-only (get-lifecycle-status (product-id (string-ascii 36)))
  (map-get? product-lifecycle { product-id: product-id })
)

(define-read-only (is-end-of-life (product-id (string-ascii 36)))
  (default-to false (get end-of-life (map-get? product-lifecycle { product-id: product-id })))
)
