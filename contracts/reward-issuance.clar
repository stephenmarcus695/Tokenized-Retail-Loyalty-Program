;; Reward Issuance Contract
;; Manages point allocation and redemption

(define-data-var admin principal tx-sender)
(define-data-var points-per-unit uint u10)  ;; 10 points per unit by default

;; Data map to store reward balances
(define-map reward-balances
  { customer-id: (string-ascii 36) }
  { points: uint }
)

;; Data map to store redemption history
(define-map redemptions
  { redemption-id: (string-ascii 36) }
  {
    customer-id: (string-ascii 36),
    points-used: uint,
    reward-type: (string-ascii 50),
    timestamp: uint
  }
)

;; Issue points based on transaction amount
(define-public (issue-points
    (customer-id (string-ascii 36))
    (tx-id (string-ascii 36))
    (amount uint))
  (let
    ((caller tx-sender)
     (points-to-add (* amount (var-get points-per-unit)))
     (current-points (default-to u0 (get points (map-get? reward-balances { customer-id: customer-id })))))
    ;; In a real implementation, we would verify the transaction here
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (ok (map-set reward-balances
      { customer-id: customer-id }
      { points: (+ current-points points-to-add) }
    ))
  )
)

;; Redeem points for rewards
(define-public (redeem-points
    (redemption-id (string-ascii 36))
    (customer-id (string-ascii 36))
    (points-to-use uint)
    (reward-type (string-ascii 50)))
  (let
    ((caller tx-sender)
     (current-points (default-to u0 (get points (map-get? reward-balances { customer-id: customer-id })))))
    ;; In a real implementation, we would verify the customer identity here
    (asserts! (>= current-points points-to-use) (err u1))
    (map-set reward-balances
      { customer-id: customer-id }
      { points: (- current-points points-to-use) }
    )
    (ok (map-set redemptions
      { redemption-id: redemption-id }
      {
        customer-id: customer-id,
        points-used: points-to-use,
        reward-type: reward-type,
        timestamp: block-height
      }
    ))
  )
)

;; Get customer point balance
(define-read-only (get-point-balance (customer-id (string-ascii 36)))
  (default-to u0 (get points (map-get? reward-balances { customer-id: customer-id })))
)

;; Get redemption details
(define-read-only (get-redemption (redemption-id (string-ascii 36)))
  (map-get? redemptions { redemption-id: redemption-id })
)

;; Update points-per-unit ratio (admin only)
(define-public (set-points-per-unit (new-ratio uint))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (ok (var-set points-per-unit new-ratio))
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
