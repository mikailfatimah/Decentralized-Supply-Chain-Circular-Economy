;; product-verification.clar
;; This contract validates items in circulation within the supply chain

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map products
  { product-id: (string-ascii 36) }
  {
    manufacturer: principal,
    creation-date: uint,
    verified: bool,
    current-owner: principal
  }
)

;; Events
(define-public (register-product (product-id (string-ascii 36)))
  (let
    ((caller tx-sender))
    (begin
      (asserts! (not (default-to false (get verified (map-get? products { product-id: product-id })))) (err u1))
      (map-set products
        { product-id: product-id }
        {
          manufacturer: caller,
          creation-date: block-height,
          verified: true,
          current-owner: caller
        }
      )
      (ok true)
    )
  )
)

(define-public (transfer-product (product-id (string-ascii 36)) (new-owner principal))
  (let
    ((product (unwrap! (map-get? products { product-id: product-id }) (err u2)))
     (caller tx-sender))
    (begin
      (asserts! (is-eq (get current-owner product) caller) (err u3))
      (map-set products
        { product-id: product-id }
        (merge product { current-owner: new-owner })
      )
      (ok true)
    )
  )
)

(define-public (verify-product (product-id (string-ascii 36)))
  (let
    ((product (map-get? products { product-id: product-id })))
    (if (is-some product)
      (ok (get verified (unwrap! product (err u4))))
      (err u4)
    )
  )
)

(define-read-only (get-product-details (product-id (string-ascii 36)))
  (map-get? products { product-id: product-id })
)
