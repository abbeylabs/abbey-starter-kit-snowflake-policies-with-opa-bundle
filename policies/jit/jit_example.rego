package jit

deny[msg] {
    expires_in := time.parse_duration_ns("24h")
    approved_at := time.parse_rfc3339_ns(data.system.abbey.target.grant.approved_at)
    expires_at := approved_at + expires_in
    now := time.now_ns()
    now - expires_at > 0
    msg := "revoking access due to 24-hour expiration"
}