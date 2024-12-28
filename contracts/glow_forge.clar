;; GlowForge - Sustainable Product Discovery Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))

;; Data Variables
(define-map brands
    { brand-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        sustainability-score: uint,
        verified: bool,
        registration-date: uint
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

(define-data-var brand-counter uint u0)
(define-data-var product-counter uint u0)

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
                registration-date: block-height
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

;; Update sustainability score
(define-public (update-sustainability-score (brand-id uint) (score uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? brands { brand-id: brand-id })
            brand
            (ok (map-set brands
                { brand-id: brand-id }
                (merge brand { sustainability-score: score })))
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