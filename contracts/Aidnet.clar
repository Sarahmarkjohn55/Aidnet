;; title: Aidnet

(define-fungible-token aid-token)

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-AMOUNT (err u1001))
(define-constant ERR-USER-NOT-FOUND (err u1002))
(define-constant ERR-EMERGENCY-NOT-FOUND (err u1003))
(define-constant ERR-ALREADY-RESPONDED (err u1004))
(define-constant ERR-NOT-QUALIFIED (err u1005))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1006))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u1007))
(define-constant ERR-VOTING-ENDED (err u1008))
(define-constant ERR-ALREADY-VOTED (err u1009))

(define-data-var emergency-counter uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var total-fund uint u0)
(define-data-var min-stake-amount uint u1000)
(define-data-var emergency-reward uint u500)
(define-data-var training-reward uint u100)

(define-map volunteers principal {
    certification-level: uint,
    total-responses: uint,
    reputation-score: uint,
    staked-amount: uint,
    active: bool,
    last-training: uint
})

(define-map emergencies uint {
    reporter: principal,
    location: (string-ascii 256),
    severity: uint,
    status: uint,
    created-at: uint,
    responder: (optional principal),
    resolved-at: (optional uint)
})

(define-map emergency-responses {emergency-id: uint, responder: principal} {
    response-time: uint,
    accepted: bool
})

(define-map proposals uint {
    proposer: principal,
    title: (string-ascii 128),
    description: (string-ascii 512),
    voting-end: uint,
    yes-votes: uint,
    no-votes: uint,
    executed: bool
})

(define-map votes {proposal-id: uint, voter: principal} bool)

(define-map training-sessions uint {
    instructor: principal,
    title: (string-ascii 128),
    date: uint,
    max-participants: uint,
    current-participants: uint,
    reward-per-participant: uint
})

(define-map training-participants {session-id: uint, participant: principal} bool)

(define-public (register-volunteer (certification-level uint))
    (let ((current-stake (stx-get-balance tx-sender)))
        (asserts! (>= current-stake (var-get min-stake-amount)) ERR-INSUFFICIENT-FUNDS)
        (try! (stx-transfer? (var-get min-stake-amount) tx-sender (as-contract tx-sender)))
        (map-set volunteers tx-sender {
            certification-level: certification-level,
            total-responses: u0,
            reputation-score: u100,
            staked-amount: (var-get min-stake-amount),
            active: true,
            last-training: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1)))
        })
        (try! (ft-mint? aid-token u100 tx-sender))
        (ok true)
    )
)

(define-public (report-emergency (location (string-ascii 256)) (severity uint))
    (let ((emergency-id (+ (var-get emergency-counter) u1)))
        (var-set emergency-counter emergency-id)
        (map-set emergencies emergency-id {
            reporter: tx-sender,
            location: location,
            severity: severity,
            status: u0,
            created-at: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))),
            responder: none,
            resolved-at: none
        })
        (try! (ft-mint? aid-token u50 tx-sender))
        (ok emergency-id)
    )
)

(define-public (respond-to-emergency (emergency-id uint))
    (let (
        (volunteer-data (unwrap! (map-get? volunteers tx-sender) ERR-NOT-QUALIFIED))
        (emergency-data (unwrap! (map-get? emergencies emergency-id) ERR-EMERGENCY-NOT-FOUND))
    )
        (asserts! (get active volunteer-data) ERR-NOT-QUALIFIED)
        (asserts! (is-none (map-get? emergency-responses {emergency-id: emergency-id, responder: tx-sender})) ERR-ALREADY-RESPONDED)
        (asserts! (is-eq (get status emergency-data) u0) ERR-ALREADY-RESPONDED)
        
        (map-set emergency-responses {emergency-id: emergency-id, responder: tx-sender} {
            response-time: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))),
            accepted: false
        })
        (ok true)
    )
)

(define-public (accept-responder (emergency-id uint) (responder principal))
    (let (
        (emergency-data (unwrap! (map-get? emergencies emergency-id) ERR-EMERGENCY-NOT-FOUND))
        (volunteer-data (unwrap! (map-get? volunteers responder) ERR-USER-NOT-FOUND))
    )
        (asserts! (is-eq tx-sender (get reporter emergency-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status emergency-data) u0) ERR-ALREADY-RESPONDED)
        
        (map-set emergencies emergency-id (merge emergency-data {
            status: u1,
            responder: (some responder)
        }))
        
        (map-set emergency-responses {emergency-id: emergency-id, responder: responder} {
            response-time: (default-to u0 (get response-time (map-get? emergency-responses {emergency-id: emergency-id, responder: responder}))),
            accepted: true
        })
        
        (try! (stx-transfer? (var-get emergency-reward) (as-contract tx-sender) responder))
        (try! (ft-mint? aid-token (var-get emergency-reward) responder))
        
        (map-set volunteers responder (merge volunteer-data {
            total-responses: (+ (get total-responses volunteer-data) u1),
            reputation-score: (+ (get reputation-score volunteer-data) u10)
        }))
        
        (ok true)
    )
)

(define-public (resolve-emergency (emergency-id uint))
    (let ((emergency-data (unwrap! (map-get? emergencies emergency-id) ERR-EMERGENCY-NOT-FOUND)))
        (asserts! (or 
            (is-eq tx-sender (get reporter emergency-data))
            (is-eq (some tx-sender) (get responder emergency-data))
        ) ERR-NOT-AUTHORIZED)
        
        (map-set emergencies emergency-id (merge emergency-data {
            status: u2,
            resolved-at: (some (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        }))
        (ok true)
    )
)

(define-public (create-training-session (title (string-ascii 128)) (date uint) (max-participants uint) (reward-per-participant uint))
    (let ((session-id (+ (var-get emergency-counter) u1)))
        (asserts! (>= (ft-get-balance aid-token tx-sender) (* reward-per-participant max-participants)) ERR-INSUFFICIENT-FUNDS)
        
        (var-set emergency-counter session-id)
        (map-set training-sessions session-id {
            instructor: tx-sender,
            title: title,
            date: date,
            max-participants: max-participants,
            current-participants: u0,
            reward-per-participant: reward-per-participant
        })
        (ok session-id)
    )
)

(define-public (join-training-session (session-id uint))
    (let ((session-data (unwrap! (map-get? training-sessions session-id) ERR-EMERGENCY-NOT-FOUND)))
        (asserts! (is-some (map-get? volunteers tx-sender)) ERR-NOT-QUALIFIED)
        (asserts! (< (get current-participants session-data) (get max-participants session-data)) ERR-INVALID-AMOUNT)
        (asserts! (is-none (map-get? training-participants {session-id: session-id, participant: tx-sender})) ERR-ALREADY-RESPONDED)
        
        (map-set training-participants {session-id: session-id, participant: tx-sender} true)
        (map-set training-sessions session-id (merge session-data {
            current-participants: (+ (get current-participants session-data) u1)
        }))
        (ok true)
    )
)

(define-public (complete-training-session (session-id uint) (participant principal))
    (let (
        (session-data (unwrap! (map-get? training-sessions session-id) ERR-EMERGENCY-NOT-FOUND))
        (volunteer-data (unwrap! (map-get? volunteers participant) ERR-USER-NOT-FOUND))
    )
        (asserts! (is-eq tx-sender (get instructor session-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? training-participants {session-id: session-id, participant: participant})) ERR-USER-NOT-FOUND)
        
        (try! (ft-transfer? aid-token (get reward-per-participant session-data) tx-sender participant))
        
        (map-set volunteers participant (merge volunteer-data {
            last-training: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))),
            reputation-score: (+ (get reputation-score volunteer-data) u5)
        }))
        (ok true)
    )
)

(define-public (create-proposal (title (string-ascii 128)) (description (string-ascii 512)) (voting-duration uint))
    (let ((proposal-id (+ (var-get proposal-counter) u1)))
        (asserts! (>= (ft-get-balance aid-token tx-sender) u100) ERR-INSUFFICIENT-FUNDS)
        
        (var-set proposal-counter proposal-id)
        (map-set proposals proposal-id {
            proposer: tx-sender,
            title: title,
            description: description,
            voting-end: (+ stacks-block-height voting-duration),
            yes-votes: u0,
            no-votes: u0,
            executed: false
        })
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool))
    (let ((proposal-data (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND)))
        (asserts! (is-some (map-get? volunteers tx-sender)) ERR-NOT-QUALIFIED)
        (asserts! (<= stacks-block-height (get voting-end proposal-data)) ERR-VOTING-ENDED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        
        (map-set votes {proposal-id: proposal-id, voter: tx-sender} vote)
        
        (if vote
            (map-set proposals proposal-id (merge proposal-data {
                yes-votes: (+ (get yes-votes proposal-data) u1)
            }))
            (map-set proposals proposal-id (merge proposal-data {
                no-votes: (+ (get no-votes proposal-data) u1)
            }))
        )
        (ok true)
    )
)

(define-public (contribute-to-fund (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set total-fund (+ (var-get total-fund) amount))
        (try! (ft-mint? aid-token (/ amount u10) tx-sender))
        (ok true)
    )
)

(define-read-only (get-volunteer (volunteer principal))
    (map-get? volunteers volunteer)
)

(define-read-only (get-emergency (emergency-id uint))
    (map-get? emergencies emergency-id)
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-training-session (session-id uint))
    (map-get? training-sessions session-id)
)

(define-read-only (get-emergency-response (emergency-id uint) (responder principal))
    (map-get? emergency-responses {emergency-id: emergency-id, responder: responder})
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-total-fund)
    (var-get total-fund)
)

(define-read-only (get-emergency-count)
    (var-get emergency-counter)
)

(define-read-only (get-proposal-count)
    (var-get proposal-counter)
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)
