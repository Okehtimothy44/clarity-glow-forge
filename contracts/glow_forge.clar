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
        block-height: uint
    }
)

;; Maps
(define-map brands
    { brand-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        sustainability-score: uint,
        verified: bool,
        registration-date: uint,
        tier: (string-ascii 16),
        reward-points: uint,
        last-update: uint
    }
)

(define-map products
    { product-id: uint }
    {
        brand-id: uint,
        name: (string-ascii 64),
        description: (string-ascii 256),
        eco-score: uint,
        certifications: (list 10 (string-ascii 32))
    }
)

(define-map brand-tiers
    { tier: (string-ascii 16) }
    {
        min-score: uint,
        reward-multiplier: uint
    }
)

;; Initialize tiers
(map-set brand-tiers
    { tier: "bronze" }
    {
        min-score: u0,
        reward-multiplier: u1
    }
)
(map-set brand-tiers
    { tier: "silver" }
    {
        min-score: u60,
        reward-multiplier: u2
    }
)
(map-set brand-tiers
    { tier: "gold" }
    {
        min-score: u80,
        reward-multiplier: u3
    }
)

;; Admin Functions
(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

;; Helper Functions
(define-private (emit-event (event-type (string-ascii 24)) (brand-id uint))
    (let
        ((event-id (+ (var-get last-event-id) u1)))
        (map-set platform-events
            { event-id: event-id }
            {
                event-type: event-type,
                brand-id: brand-id,
                block-height: block-height
            }
        )
        (var-set last-event-id event-id)
        event-id
    )
)

(define-private (validate-score (score uint))
    (and (>= score u0) (<= score u100))
)

;; Public Functions
(define-public (register-brand (name (string-ascii 64)))
    (begin
        (asserts! (not (var-get contract-paused)) err-contract-paused)
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

;; Update brand profile
(define-public (update-brand-profile 
    (brand-id uint)
    (name (string-ascii 64))
)
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

[... Rest of the original contract functions ...]
