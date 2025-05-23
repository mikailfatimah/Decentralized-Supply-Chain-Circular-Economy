;; material-passport.clar
;; This contract records component composition of products

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map material-passports
  { product-id: (string-ascii 36) }
  {
    materials: (list 20 (string-ascii 64)),
    percentages: (list 20 uint),
    recyclable: bool,
    last-updated: uint
  }
)

;; Events
(define-public (create-material-passport
                (product-id (string-ascii 36))
                (materials (list 20 (string-ascii 64)))
                (percentages (list 20 uint))
                (recyclable bool))
  (let
    ((caller tx-sender))
    (begin
      (asserts! (not (is-some (map-get? material-passports { product-id: product-id }))) (err u1))
      (asserts! (is-eq (len materials) (len percentages)) (err u2))
      (map-set material-passports
        { product-id: product-id }
        {
          materials: materials,
          percentages: percentages,
          recyclable: recyclable,
          last-updated: block-height
        }
      )
      (ok true)
    )
  )
)

(define-public (update-material-passport
                (product-id (string-ascii 36))
                (materials (list 20 (string-ascii 64)))
                (percentages (list 20 uint))
                (recyclable bool))
  (let
    ((passport (unwrap! (map-get? material-passports { product-id: product-id }) (err u3)))
     (caller tx-sender))
    (begin
      (asserts! (is-eq (len materials) (len percentages)) (err u2))
      (map-set material-passports
        { product-id: product-id }
        {
          materials: materials,
          percentages: percentages,
          recyclable: recyclable,
          last-updated: block-height
        }
      )
      (ok true)
    )
  )
)

(define-read-only (get-material-passport (product-id (string-ascii 36)))
  (map-get? material-passports { product-id: product-id })
)

(define-read-only (is-recyclable (product-id (string-ascii 36)))
  (default-to false (get recyclable (map-get? material-passports { product-id: product-id })))
)
