(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NO-ACCESS (err u403))
(define-constant ERR-JOB-NOT-FOUND (err u404))
(define-constant ERR-JOB-CLOSED (err u405))
(define-constant ERR-BID-TOO-LOW (err u406))

;; Job states
(define-constant JOB-STATE-OPEN u1)
(define-constant JOB-STATE-COMPLETED u2)

;; Job structure
(define-map jobs 
  { job-id: uint }
  {
    project-title: (string-utf8 100),
    scope: (string-utf8 500),
    max-budget: uint,
    lowest-bid: uint,
    selected-freelancer: (optional principal),
    status: uint,
    client: principal
  }
)

;; Bid tracking
(define-map bids
  { job-id: uint, freelancer: principal }
  { bid-amount: uint }
)

;; Job ID counter
(define-data-var next-job-id uint u0)

;; Post a new job
(define-public (post-job
  (project-title (string-utf8 100))
  (scope (string-utf8 500))
  (max-budget uint)
)
  (let 
    ((job-id (var-get next-job-id)))
    (map-set jobs 
      { job-id: job-id }
      {
        project-title: project-title,
        scope: scope,
        max-budget: max-budget,
        lowest-bid: max-budget,
        selected-freelancer: none,
        status: JOB-STATE-OPEN,
        client: tx-sender
      }
    )
    (var-set next-job-id (+ job-id u1))
    (ok job-id)
  )
)

;; Submit bid
(define-public (submit-bid
  (job-id uint)
  (bid-amount uint)
)
  (let 
    (
      (job (unwrap! (map-get? jobs { job-id: job-id }) ERR-JOB-NOT-FOUND))
      (current-bid (get lowest-bid job))
    )
    (asserts! (is-eq (get status job) JOB-STATE-OPEN) ERR-JOB-CLOSED)
    (asserts! (< bid-amount current-bid) ERR-BID-TOO-LOW)

    (map-set jobs 
      { job-id: job-id }
      (merge job {
        lowest-bid: bid-amount,
        selected-freelancer: (some tx-sender)
      })
    )

    (map-set bids
      { job-id: job-id, freelancer: tx-sender }
      { bid-amount: bid-amount }
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-job-details (job-id uint))
  (map-get? jobs { job-id: job-id })
)

(define-read-only (get-job-status (job-id uint))
  (match (map-get? jobs { job-id: job-id })
    job (some (get status job))
    none
  )
)