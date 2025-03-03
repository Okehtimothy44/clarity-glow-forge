;; GlowForge - Sustainable Product Discovery Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))
(define-constant err-invalid-tier (err u104))
(define-constant err-invalid-score (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-invalid-input (err u107))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var brand-counter uint u0)
(define-data-var product-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map platform-events
    { event-id: uint }
    {
        event-type: (string-ascii 24),
        brand-id: uint,
        block-height: uint,
        details: (optional (string-ascii 64))
    }
)

;; Maps
[... Original maps remain unchanged ...]

;; Helper Functions
(define-private (validate-brand-name (name (string-ascii 64)))
    (match (slice? name 0 1)
        success true
        failure false
    )
)

(define-private (calculate-brand-tier (score uint))
    (if (>= score u80)
        "gold"
        (if (>= score u60)
            "silver"
            "bronze"
        )
    )
)

(define-read-only (get-brand-by-owner (owner principal))
    (let ((brand-id (default-to u0 (find-brand-by-owner owner))))
        (if (is-eq brand-id u0)
            none
            (map-get? brands { brand-id: brand-id })
        )
    )
)

(define-private (find-brand-by-owner (owner principal))
    (define-private (check-owner (id uint))
        (match (map-get? brands { brand-id: id })
            brand (is-eq (get owner brand) owner)
            false
        )
    )
    (find check-owner (list u1 u2 u3 u4 u5))
)

;; Public Functions
(define-public (register-brand (name (string-ascii 64)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
        (asserts! (validate-brand-name name) err-invalid-input)
        (let
            (
                (brand-id (+ (var-get brand-counter) u1))
            )
            (asserts! (is-none (get-brand-by-owner tx-sender)) err-already-registered)
            (map-set brands
                { brand-id: brand-id }
                {
                    name: name,
                    owner: tx-sender,
                    sustainability-score: u0,
                    verified: false,
                    registration-date: block-height,
                    tier: "bronze",
                    reward-points: u0,
                    last-update: block-height
                }
            )
            (var-set brand-counter brand-id)
            (emit-event "brand-registered" brand-id)
            (ok brand-id)
        )
    )
)

(define-public (update-brand-profile 
    (brand-id uint)
    (name (string-ascii 64))
)
    (begin
        (asserts! (>= brand-id u1) err-invalid-input)
        (asserts! (<= brand-id (var-get brand-counter)) err-not-found)
        (asserts! (validate-brand-name name) err-invalid-input)
        (let
            ((brand (unwrap! (get-brand-by-id brand-id) err-not-found)))
            (asserts! (is-eq (get owner brand) tx-sender) err-unauthorized)
            (ok (map-set brands
                { brand-id: brand-id }
                (merge brand {
                    name: name,
                    last-update: block-height
                })))
        )
    )
)

[... Rest of the original contract functions ...]
