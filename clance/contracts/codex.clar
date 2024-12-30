(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NO-ACCESS (err u403))
(define-constant ERR-JOB-NOT-FOUND (err u404))
(define-constant ERR-JOB-CLOSED (err u405))
(define-constant ERR-BID-TOO-LOW (err u406))
(define-constant ERR-JOB-IN-PROGRESS (err u407))
(define-constant ERR-BAD-PARAMS (err u409))

;; Job states
(define-constant JOB-STATE-DRAFT u0)
(define-constant JOB-STATE-OPEN u1)
(define-constant JOB-STATE-COMPLETED u2)

;; Configuration constants
(define-constant MIN-BID-DECREASE-PERCENT u10)
(define-constant MAX-JOB-DURATION u144000)
(define-constant MIN-JOB-DURATION u1440)

;; Job structure
(define-map jobs 
  { job-id: uint }
  {
    project-title: (string-utf8 100),
    scope: (string-utf8 500),
    max-budget: uint,
    min-budget: (optional uint),
    lowest-bid: uint,
    selected-freelancer: (optional principal),
    post-block: uint,
    deadline-block: uint,
    status: uint,
    client: principal
  }
)

;; Bid tracking
(define-map bids
  { job-id: uint, freelancer: principal }
  { 
    bid-amount: uint,
    bid-time: uint
  }
)

;; Job ID counter
(define-data-var next-job-id uint u0)

;; Validate bid decrease
(define-private (is-valid-bid-decrease 
  (current-bid uint) 
  (new-bid uint)
)
  (let 
    (
      (min-next-bid (- current-bid 
        (/ (* current-bid MIN-BID-DECREASE-PERCENT) u100)
      ))
    )
    (<= new-bid min-next-bid)
  )
)

;; Validate job parameters
(define-private (validate-job-params
  (max-budget uint)
  (min-budget (optional uint))
  (post-block uint)
  (deadline-block uint)
)
  (and
    (> max-budget u0)
    (< post-block deadline-block)
    (<= (- deadline-block post-block) MAX-JOB-DURATION)
    (>= (- deadline-block post-block) MIN-JOB-DURATION)
    (match min-budget
      price (< price max-budget)
      true)
  )
)

;; Post a new job
(define-public (post-job
  (project-title (string-utf8 100))
  (scope (string-utf8 500))
  (max-budget uint)
  (min-budget (optional uint))
  (post-block uint)
  (deadline-block uint)
)
  (begin
    (asserts! 
      (validate-job-params 
        max-budget 
        min-budget 
        post-block 
        deadline-block
      ) 
      ERR-BAD-PARAMS
    )

    (let 
      ((job-id (var-get next-job-id)))
      (map-set jobs 
        { job-id: job-id }
        {
          project-title: project-title,
          scope: scope,
          max-budget: max-budget,
          min-budget: min-budget,
          lowest-bid: max-budget,
          selected-freelancer: none,
          post-block: post-block,
          deadline-block: deadline-block,
          status: JOB-STATE-DRAFT,
          client: tx-sender
        }
      )

      (var-set next-job-id (+ job-id u1))
      (ok job-id)
    )
  )
)

;; Submit bid
(define-public (submit-bid
  (job-id uint)
  (bid-amount uint)
  (current-block uint)
)
  (let 
    (
      (job (unwrap! (map-get? jobs { job-id: job-id }) ERR-JOB-NOT-FOUND))
      (current-bid (get lowest-bid job))
    )
    (asserts! (is-eq (get status job) JOB-STATE-OPEN) ERR-JOB-CLOSED)
    (asserts! (< current-block (get deadline-block job)) ERR-JOB-CLOSED)
    (asserts! (is-valid-bid-decrease current-bid bid-amount) ERR-BID-TOO-LOW)

    (match (get min-budget job)
      price (asserts! (>= bid-amount price) ERR-BID-TOO-LOW)
      true
    )

    (map-set jobs 
      { job-id: job-id }
      (merge job {
        lowest-bid: bid-amount,
        selected-freelancer: (some tx-sender)
      })
    )

    (map-set bids
      { job-id: job-id, freelancer: tx-sender }
      { 
        bid-amount: bid-amount,
        bid-time: current-block
      }
    )

    (ok true)
  )
)

;; Publish job listing
(define-public (publish-job 
  (job-id uint)
  (current-block uint)
)
  (let 
    ((job (unwrap! (map-get? jobs { job-id: job-id }) ERR-JOB-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get client job)) ERR-NO-ACCESS)
    (asserts! (is-eq (get status job) JOB-STATE-DRAFT) ERR-JOB-IN-PROGRESS)
    (asserts! (>= current-block (get post-block job)) ERR-JOB-NOT-FOUND)

    (map-set jobs
      { job-id: job-id }
      (merge job { status: JOB-STATE-OPEN })
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