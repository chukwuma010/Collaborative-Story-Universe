;; Collaborative Story Universe - Shared fictional worlds where creators earn from contributions
;; A decentralized platform for collaborative storytelling with creator rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-already-exists (err u105))

;; Data Variables
(define-data-var next-story-id uint u1)
(define-data-var next-contribution-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Data Maps
(define-map stories
  { story-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    created-at: uint,
    total-contributions: uint,
    total-earnings: uint,
    is-active: bool,
    genre: (string-ascii 50),
    max-contributors: uint
  }
)

(define-map story-contributions
  { contribution-id: uint }
  {
    story-id: uint,
    contributor: principal,
    content: (string-ascii 1000),
    contribution-type: (string-ascii 20), ;; "chapter", "character", "plot", "setting"
    created-at: uint,
    upvotes: uint,
    earnings: uint,
    is-approved: bool
  }
)

(define-map story-contributors
  { story-id: uint, contributor: principal }
  {
    total-contributions: uint,
    total-earnings: uint,
    join-date: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 50),
    bio: (string-ascii 200),
    total-stories-created: uint,
    total-contributions: uint,
    reputation-score: uint,
    total-earnings: uint
  }
)

(define-map story-votes
  { story-id: uint, voter: principal, contribution-id: uint }
  { has-voted: bool }
)

(define-map revenue-sharing
  { story-id: uint }
  {
    creator-percentage: uint,
    contributors-pool-percentage: uint,
    platform-percentage: uint
  }
)

;; Public Functions

;; Create a new story universe
(define-public (create-story (title (string-ascii 100)) 
                           (description (string-ascii 500))
                           (genre (string-ascii 50))
                           (max-contributors uint))
  (let
    (
      (story-id (var-get next-story-id))
      (creator tx-sender)
    )
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (> max-contributors u0) err-invalid-input)
    
    ;; Create the story
    (map-set stories
      { story-id: story-id }
      {
        title: title,
        description: description,
        creator: creator,
        created-at: block-height,
        total-contributions: u0,
        total-earnings: u0,
        is-active: true,
        genre: genre,
        max-contributors: max-contributors
      }
    )
    
    ;; Set revenue sharing (60% creator, 35% contributors, 5% platform)
    (map-set revenue-sharing
      { story-id: story-id }
      {
        creator-percentage: u60,
        contributors-pool-percentage: u35,
        platform-percentage: u5
      }
    )
    
    ;; Update creator profile
    (update-user-profile creator u1 u0 u0)
    
    ;; Increment story ID
    (var-set next-story-id (+ story-id u1))
    
    (ok story-id)
  )
)

;; Contribute to a story
(define-public (contribute-to-story (story-id uint)
                                  (content (string-ascii 1000))
                                  (contribution-type (string-ascii 20)))
  (let
    (
      (contribution-id (var-get next-contribution-id))
      (contributor tx-sender)
      (story-info (unwrap! (map-get? stories { story-id: story-id }) err-not-found))
    )
    (asserts! (get is-active story-info) err-unauthorized)
    (asserts! (> (len content) u0) err-invalid-input)
    (asserts! (< (get total-contributions story-info) (get max-contributors story-info)) err-unauthorized)
    
    ;; Create contribution
    (map-set story-contributions
      { contribution-id: contribution-id }
      {
        story-id: story-id,
        contributor: contributor,
        content: content,
        contribution-type: contribution-type,
        created-at: block-height,
        upvotes: u0,
        earnings: u0,
        is-approved: false
      }
    )
    
    ;; Update story stats
    (map-set stories
      { story-id: story-id }
      (merge story-info { total-contributions: (+ (get total-contributions story-info) u1) })
    )
    
    ;; Update contributor stats
    (update-story-contributor story-id contributor)
    
    ;; Update user profile
    (update-user-profile contributor u0 u1 u0)
    
    ;; Increment contribution ID
    (var-set next-contribution-id (+ contribution-id u1))
    
    (ok contribution-id)
  )
)

;; Vote on a contribution (upvote system)
(define-public (vote-contribution (story-id uint) (contribution-id uint))
  (let
    (
      (voter tx-sender)
      (contribution-info (unwrap! (map-get? story-contributions { contribution-id: contribution-id }) err-not-found))
    )
    (asserts! (is-eq (get story-id contribution-info) story-id) err-invalid-input)
    (asserts! (is-none (map-get? story-votes { story-id: story-id, voter: voter, contribution-id: contribution-id })) err-already-exists)
    
    ;; Record vote
    (map-set story-votes
      { story-id: story-id, voter: voter, contribution-id: contribution-id }
      { has-voted: true }
    )
    
    ;; Increment upvotes
    (map-set story-contributions
      { contribution-id: contribution-id }
      (merge contribution-info { upvotes: (+ (get upvotes contribution-info) u1) })
    )
    
    (ok true)
  )
)

;; Approve contribution (story creator only)
(define-public (approve-contribution (contribution-id uint))
  (let
    (
      (contribution-info (unwrap! (map-get? story-contributions { contribution-id: contribution-id }) err-not-found))
      (story-info (unwrap! (map-get? stories { story-id: (get story-id contribution-info) }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator story-info)) err-unauthorized)
    
    ;; Approve contribution
    (map-set story-contributions
      { contribution-id: contribution-id }
      (merge contribution-info { is-approved: true })
    )
    
    (ok true)
  )
)

;; Distribute earnings to contributors based on their contributions and votes
(define-public (distribute-earnings (story-id uint) (total-amount uint))
  (let
    (
      (story-info (unwrap! (map-get? stories { story-id: story-id }) err-not-found))
      (revenue-info (unwrap! (map-get? revenue-sharing { story-id: story-id }) err-not-found))
      (creator-share (/ (* total-amount (get creator-percentage revenue-info)) u100))
      (contributors-share (/ (* total-amount (get contributors-pool-percentage revenue-info)) u100))
      (platform-share (/ (* total-amount (get platform-percentage revenue-info)) u100))
    )
    (asserts! (is-eq tx-sender (get creator story-info)) err-unauthorized)
    
    ;; Update story earnings
    (map-set stories
      { story-id: story-id }
      (merge story-info { total-earnings: (+ (get total-earnings story-info) total-amount) })
    )
    
    ;; Note: In a complete implementation, you would distribute STX tokens here
    ;; This would require the contract to hold and manage STX balances
    
    (ok { creator-share: creator-share, contributors-share: contributors-share, platform-share: platform-share })
  )
)

;; Create or update user profile
(define-public (create-user-profile (username (string-ascii 50)) (bio (string-ascii 200)))
  (let
    (
      (user tx-sender)
      (existing-profile (map-get? user-profiles { user: user }))
    )
    (asserts! (> (len username) u0) err-invalid-input)
    
    (map-set user-profiles
      { user: user }
      {
        username: username,
        bio: bio,
        total-stories-created: (default-to u0 (get total-stories-created existing-profile)),
        total-contributions: (default-to u0 (get total-contributions existing-profile)),
        reputation-score: (default-to u0 (get reputation-score existing-profile)),
        total-earnings: (default-to u0 (get total-earnings existing-profile))
      }
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get story information
(define-read-only (get-story (story-id uint))
  (map-get? stories { story-id: story-id })
)

;; Get contribution information
(define-read-only (get-contribution (contribution-id uint))
  (map-get? story-contributions { contribution-id: contribution-id })
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

;; Get story contributor stats
(define-read-only (get-story-contributor (story-id uint) (contributor principal))
  (map-get? story-contributors { story-id: story-id, contributor: contributor })
)

;; Get revenue sharing info
(define-read-only (get-revenue-sharing (story-id uint))
  (map-get? revenue-sharing { story-id: story-id })
)

;; Check if user has voted on contribution
(define-read-only (has-voted (story-id uint) (voter principal) (contribution-id uint))
  (is-some (map-get? story-votes { story-id: story-id, voter: voter, contribution-id: contribution-id }))
)

;; Get next story ID
(define-read-only (get-next-story-id)
  (var-get next-story-id)
)

;; Get next contribution ID
(define-read-only (get-next-contribution-id)
  (var-get next-contribution-id)
)

;; Private functions

;; Update user profile stats
(define-private (update-user-profile (user principal) (stories-created uint) (contributions uint) (earnings uint))
  (let
    (
      (existing-profile (map-get? user-profiles { user: user }))
    )
    (map-set user-profiles
      { user: user }
      {
        username: (default-to "" (get username existing-profile)),
        bio: (default-to "" (get bio existing-profile)),
        total-stories-created: (+ (default-to u0 (get total-stories-created existing-profile)) stories-created),
        total-contributions: (+ (default-to u0 (get total-contributions existing-profile)) contributions),
        reputation-score: (default-to u0 (get reputation-score existing-profile)),
        total-earnings: (+ (default-to u0 (get total-earnings existing-profile)) earnings)
      }
    )
  )
)

;; Update story contributor stats
(define-private (update-story-contributor (story-id uint) (contributor principal))
  (let
    (
      (existing-stats (map-get? story-contributors { story-id: story-id, contributor: contributor }))
    )
    (map-set story-contributors
      { story-id: story-id, contributor: contributor }
      {
        total-contributions: (+ (default-to u0 (get total-contributions existing-stats)) u1),
        total-earnings: (default-to u0 (get total-earnings existing-stats)),
        join-date: (default-to block-height (get join-date existing-stats))
      }
    )
  )
)