;; GlowForge - Sustainable Product Discovery Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))
(define-constant err-invalid-tier (err u104))

;; Data Variables
(define-map brands
    { brand-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        sustainability-score: uint,
        verified: bool,
        registration-date: uint,
        tier: (string-ascii 16),
        reward-points: uint
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

(define-data-var brand-counter uint u0)
(define-data-var product-counter uint u0)

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

;; Public Functions

;; Register new brand
(define-public (register-brand (name (string-ascii 64)))
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
                reward-points: u0
            }
        )
        (var-set brand-counter brand-id)
        (ok brand-id)
    )
)

;; Add new product
(define-public (add-product 
    (brand-id uint)
    (name (string-ascii 64))
    (description (string-ascii 256))
    (eco-score uint)
    (certifications (list 10 (string-ascii 32)))
)
    (let
        (
            (brand (unwrap! (get-brand-by-id brand-id) err-not-found))
            (product-id (+ (var-get product-counter) u1))
            (brand-info (unwrap! (map-get? brands { brand-id: brand-id }) err-not-found))
            (tier-info (unwrap! (map-get? brand-tiers { tier: (get tier brand-info) }) err-invalid-tier))
        )
        (asserts! (is-eq (get owner brand) tx-sender) err-unauthorized)
        (map-set products
            { product-id: product-id }
            {
                brand-id: brand-id,
                name: name,
                description: description,
                eco-score: eco-score,
                certifications: certifications
            }
        )
        ;; Award reward points based on tier
        (map-set brands
            { brand-id: brand-id }
            (merge brand-info {
                reward-points: (+ (get reward-points brand-info)
                                (* u10 (get reward-multiplier tier-info)))
            })
        )
        (var-set product-counter product-id)
        (ok product-id)
    )
)

;; Verify brand (owner only)
(define-public (verify-brand (brand-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? brands { brand-id: brand-id })
            brand
            (ok (map-set brands
                { brand-id: brand-id }
                (merge brand { verified: true })))
            err-not-found
        )
    )
)

;; Update sustainability score and tier
(define-public (update-sustainability-score (brand-id uint) (score uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? brands { brand-id: brand-id })
            brand
            (let
                (
                    (new-tier (get-tier-for-score score))
                )
                (ok (map-set brands
                    { brand-id: brand-id }
                    (merge brand {
                        sustainability-score: score,
                        tier: new-tier
                    })))
            )
            err-not-found
        )
    )
)

;; Read Only Functions

(define-read-only (get-brand-by-id (brand-id uint))
    (map-get? brands { brand-id: brand-id })
)

(define-read-only (get-brand-by-owner (owner principal))
    (filter map-get? brands (map-get? brands { owner: owner }))
)

(define-read-only (get-product-by-id (product-id uint))
    (map-get? products { product-id: product-id })
)

(define-read-only (get-tier-info (tier (string-ascii 16)))
    (map-get? brand-tiers { tier: tier })
)

(define-read-only (get-tier-for-score (score uint))
    (if (>= score u80)
        "gold"
        (if (>= score u60)
            "silver"
            "bronze"
        )
    )
)
