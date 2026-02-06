(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-resolved (err u102))
(define-constant err-market-closed (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-no-winnings (err u105))
(define-constant err-already-claimed (err u106))
(define-constant err-market-active (err u107))
(define-constant err-insufficient-reputation (err u108))
(define-constant err-invalid-outcome (err u109))

(define-data-var market-nonce uint u0)
(define-data-var ai-agent principal tx-sender)
(define-data-var ai-reputation uint u1000)
(define-data-var ai-total-bets uint u0)
(define-data-var ai-correct-bets uint u0)

(define-map markets
  uint
  {
    creator: principal,
    question: (string-ascii 256),
    deadline: uint,
    resolved: bool,
    outcome: (optional bool),
    total-yes: uint,
    total-no: uint,
    resolution-time: uint
  }
)

(define-map user-bets
  {market-id: uint, user: principal}
  {
    yes-amount: uint,
    no-amount: uint,
    claimed: bool
  }
)

(define-map ai-bets
  uint
  {
    position: bool,
    amount: uint,
    reputation-stake: uint,
    claimed: bool
  }
)

(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

(define-read-only (get-user-bet (market-id uint) (user principal))
  (map-get? user-bets {market-id: market-id, user: user})
)

(define-read-only (get-ai-bet (market-id uint))
  (map-get? ai-bets market-id)
)

(define-read-only (get-ai-reputation)
  (ok {
    reputation: (var-get ai-reputation),
    total-bets: (var-get ai-total-bets),
    correct-bets: (var-get ai-correct-bets),
    accuracy: (if (> (var-get ai-total-bets) u0)
                 (/ (* (var-get ai-correct-bets) u100) (var-get ai-total-bets))
                 u0)
  })
)

(define-read-only (get-market-stats (market-id uint))
  (match (map-get? markets market-id)
    market (let
      (
        (ai-bet-data (map-get? ai-bets market-id))
      )
      (ok {
        total-pool: (+ (get total-yes market) (get total-no market)),
        yes-odds: (if (> (get total-no market) u0)
                     (/ (* (get total-yes market) u100) (get total-no market))
                     u100),
        no-odds: (if (> (get total-yes market) u0)
                    (/ (* (get total-no market) u100) (get total-yes market))
                    u100),
        yes-percentage: (if (> (+ (get total-yes market) (get total-no market)) u0)
                           (/ (* (get total-yes market) u100) 
                              (+ (get total-yes market) (get total-no market)))
                           u50),
        ai-position: (match ai-bet-data
                       bet-info (some (get position bet-info))
                       none)
      })
    )
    (err err-not-found)
  )
)

(define-public (create-market (question (string-ascii 256)) (deadline uint))
  (let
    (
      (market-id (+ (var-get market-nonce) u1))
    )
    (asserts! (> deadline stacks-block-height) err-market-closed)
    (map-set markets market-id {
      creator: tx-sender,
      question: question,
      deadline: deadline,
      resolved: false,
      outcome: none,
      total-yes: u0,
      total-no: u0,
      resolution-time: u0
    })
    (var-set market-nonce market-id)
    (ok market-id)
  )
)

(define-public (place-bet (market-id uint) (position bool) (amount uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (current-bet (default-to 
        {yes-amount: u0, no-amount: u0, claimed: false}
        (map-get? user-bets {market-id: market-id, user: tx-sender})))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (<= stacks-block-height (get deadline market)) err-market-closed)
    
    (if position
      (begin
        (map-set markets market-id 
          (merge market {total-yes: (+ (get total-yes market) amount)}))
        (map-set user-bets {market-id: market-id, user: tx-sender}
          (merge current-bet {yes-amount: (+ (get yes-amount current-bet) amount)}))
      )
      (begin
        (map-set markets market-id 
          (merge market {total-no: (+ (get total-no market) amount)}))
        (map-set user-bets {market-id: market-id, user: tx-sender}
          (merge current-bet {no-amount: (+ (get no-amount current-bet) amount)}))
      )
    )
    (ok true)
  )
)

(define-public (ai-bet (market-id uint) (position bool) (amount uint) (reputation-stake uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (var-get ai-agent)) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (<= stacks-block-height (get deadline market)) err-market-closed)
    (asserts! (<= reputation-stake (var-get ai-reputation)) err-insufficient-reputation)
    (asserts! (is-none (map-get? ai-bets market-id)) err-already-claimed)
    
    (if position
      (map-set markets market-id 
        (merge market {total-yes: (+ (get total-yes market) amount)}))
      (map-set markets market-id 
        (merge market {total-no: (+ (get total-no market) amount)}))
    )
    
    (map-set ai-bets market-id {
      position: position,
      amount: amount,
      reputation-stake: reputation-stake,
      claimed: false
    })
    
    (var-set ai-total-bets (+ (var-get ai-total-bets) u1))
    (ok true)
  )
)

(define-public (resolve-market (market-id uint) (outcome bool))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (ai-bet-data (map-get? ai-bets market-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get resolved market)) err-already-resolved)
    (asserts! (> stacks-block-height (get deadline market)) err-market-active)
    
    (map-set markets market-id 
      (merge market {
        resolved: true,
        outcome: (some outcome),
        resolution-time: stacks-block-height
      }))
    
    (match ai-bet-data
      bet-info (if (is-eq (get position bet-info) outcome)
               (begin
                 (var-set ai-reputation 
                   (+ (var-get ai-reputation) (get reputation-stake bet-info)))
                 (var-set ai-correct-bets (+ (var-get ai-correct-bets) u1))
                 (ok true)
               )
               (begin
                 (var-set ai-reputation 
                   (if (>= (var-get ai-reputation) (get reputation-stake bet-info))
                      (- (var-get ai-reputation) (get reputation-stake bet-info))
                      u0))
                 (ok true)
               )
             )
      (ok true)
    )
  )
)

(define-public (claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (user-bet (unwrap! (map-get? user-bets {market-id: market-id, user: tx-sender}) err-not-found))
      (outcome (unwrap! (get outcome market) err-not-found))
    )
    (asserts! (get resolved market) err-market-active)
    (asserts! (not (get claimed user-bet)) err-already-claimed)
    
    (let
      (
        (winning-amount (if outcome 
                          (get yes-amount user-bet)
                          (get no-amount user-bet)))
        (total-winning-pool (if outcome 
                              (get total-yes market)
                              (get total-no market)))
        (total-losing-pool (if outcome 
                             (get total-no market)
                             (get total-yes market)))
        (payout (if (> total-winning-pool u0)
                   (+ winning-amount 
                      (/ (* winning-amount total-losing-pool) total-winning-pool))
                   u0))
      )
      (asserts! (> payout u0) err-no-winnings)
      
      (map-set user-bets {market-id: market-id, user: tx-sender}
        (merge user-bet {claimed: true}))
      
      (ok payout)
    )
  )
)

(define-public (ai-claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (ai-bet-info (unwrap! (map-get? ai-bets market-id) err-not-found))
      (outcome (unwrap! (get outcome market) err-not-found))
    )
    (asserts! (is-eq tx-sender (var-get ai-agent)) err-owner-only)
    (asserts! (get resolved market) err-market-active)
    (asserts! (not (get claimed ai-bet-info)) err-already-claimed)
    (asserts! (is-eq (get position ai-bet-info) outcome) err-no-winnings)
    
    (let
      (
        (total-winning-pool (if outcome 
                              (get total-yes market)
                              (get total-no market)))
        (total-losing-pool (if outcome 
                             (get total-no market)
                             (get total-yes market)))
        (payout (if (> total-winning-pool u0)
                   (+ (get amount ai-bet-info)
                      (/ (* (get amount ai-bet-info) total-losing-pool) total-winning-pool))
                   u0))
      )
      (map-set ai-bets market-id (merge ai-bet-info {claimed: true}))
      (ok payout)
    )
  )
)

(define-public (set-ai-agent (new-agent principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set ai-agent new-agent)
    (ok true)
  )
)