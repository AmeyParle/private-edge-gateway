# INC-001: Application Gateway backend unhealthy

**Service:** Private Edge Gateway  
**Severity:** SEV-2 (partial degradation)

---

## Summary

One backend instance in the VM Scale Set became unhealthy, reducing available capacity behind the Application Gateway.

---

## Detection

- Application Gateway backend health showed **1/2 Unhealthy**
- Metrics indicated reduced healthy host count

---

## Root Cause

- nginx service stopped on one VM Scale Set instance (simulated failure)

---

## Impact

- Reduced backend capacity
- Potential intermittent request failures depending on load balancing behavior
- Service remained partially available via healthy instance

---

## Mitigation

- nginx service restarted on affected instance
- Backend health automatically recovered via Application Gateway probes

---

## Verification

- Backend health returned to **Healthy**
- Application Gateway successfully routed traffic
- Browser access returned HTTP 200

---

## Lessons Learned

- Health probes provide fast detection of backend failures
- Partial backend failure does not necessarily cause total outage
- Centralized ingress simplifies failure isolation and recovery

---

## Evidence

Screenshots:
- Backend unhealthy state
- Backend recovered state
- Application Gateway metrics

Located in:
docs/screenshots/