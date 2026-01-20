# Operational Runbook — Private Edge Gateway

## Verify Service Availability

1. Azure Portal → Application Gateway
2. Copy Frontend Public IP
3. Open in browser: http://<APPGW_PUBLIC_IP>


Expected result:
- HTTP 200
- Nginx landing page displayed

---

## Check Backend Health

Azure Portal → Application Gateway → Backend health

Expected:
- All VM Scale Set instances marked **Healthy**

---

## Monitoring

Azure Portal → Application Gateway → Metrics

Recommended metrics:
- Healthy Host Count
- Failed Requests

---

## Incident Recovery (Manual)

If a backend becomes unhealthy:
- Restart nginx on affected VM instance
- Wait for health probe to recover
- Verify backend health returns to Healthy
