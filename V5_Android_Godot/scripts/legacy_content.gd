extends RefCounted
class_name Content

static func topics() -> Array:
	return [
		{"name": "Incident Management",
		"lesson": "An incident is an unplanned interruption or drop in the quality of an IT service. The goal is to restore service quickly. Priority is usually worked out from impact (how many people or services are affected) and urgency (how fast it must be fixed).",
		"ex": "Example: email is down for the whole sales team. High impact + high urgency = high priority.",
		"qs": [
			{"q": "How is incident priority usually decided?", "o": ["Impact and urgency", "Alphabetical order", "Who logged it", "Time of day"], "a": 0, "why": "Priority comes from impact and urgency."},
			{"q": "What is the main goal of incident management?", "o": ["Find the root cause forever", "Restore normal service quickly", "Approve changes", "Write articles only"], "a": 1, "why": "Fast restoration comes first. Root cause belongs to problem management."}]},
		{"name": "Business Rules",
		"lesson": "A Business Rule is server-side logic that runs when a record is inserted, updated, deleted or queried. A 'before' rule runs before the record is saved, so it can change field values. An 'after' rule runs once the record is saved.",
		"ex": "Example: before insert, set priority to 1 when impact and urgency are both high.",
		"qs": [
			{"q": "Where does a Business Rule run?", "o": ["In the user's browser", "On the server", "Only on mobile", "In the email client"], "a": 1, "why": "Business Rules are server-side."},
			{"q": "You want to change a field before the record is saved. Which timing?", "o": ["Before", "After", "Never", "Only on delete"], "a": 0, "why": "A before rule can change values that are about to be saved."}]},
		{"name": "GlideRecord",
		"lesson": "GlideRecord is a server-side scripting class used to query and change records in a table. You build the query, call query() to run it, then loop with next() to read each row.",
		"ex": "var gr = new GlideRecord('incident');\ngr.addQuery('priority', 1);\ngr.query();\nwhile (gr.next()) {\n  gs.info(gr.number);\n}",
		"qs": [
			{"q": "Which method actually runs the query?", "o": ["addQuery()", "query()", "get()", "setLimit()"], "a": 1, "why": "addQuery only adds a condition. query() executes it."},
			{"q": "What does next() do in the loop?", "o": ["Deletes the record", "Moves to the next record, true if there is one", "Saves the record", "Opens a form"], "a": 1, "why": "next() advances to the next row and returns false when there are no more."}]},
		{"name": "CMDB",
		"lesson": "The CMDB stores configuration items (CIs) such as servers, applications and databases, and the relationships between them. Knowing the relationships shows what a failure will affect.",
		"ex": "Example: a web application depends on a database server, which runs on a virtual host.",
		"qs": [
			{"q": "What does the CMDB store?", "o": ["Only passwords", "CIs and their relationships", "Email templates", "Only incidents"], "a": 1, "why": "It is a map of CIs and how they connect."},
			{"q": "Why do relationships matter?", "o": ["Colourful forms", "They show what is impacted when a CI fails", "Faster email", "They replace backups"], "a": 1, "why": "Relationships let you assess impact quickly."}]},
		{"name": "Service Catalog",
		"lesson": "The service catalog lets users request things such as a laptop or software access. Each catalog item can have variables that collect details, and a flow that fulfils the request.",
		"ex": "Example: request a laptop. Variables ask for model and manager; a flow handles approval and delivery.",
		"qs": [
			{"q": "A user needs new software installed. Best record?", "o": ["Incident", "Catalog request", "Problem", "Nothing"], "a": 1, "why": "It is a request for something, not a failure."},
			{"q": "What do catalog item variables do?", "o": ["Collect details from the requester", "Store the CMDB", "Encrypt data", "Close incidents"], "a": 0, "why": "Variables gather the information needed to fulfil the request."}]},
		{"name": "REST Integration",
		"lesson": "REST integrations let systems exchange data over HTTP. GET reads, POST creates, PUT or PATCH updates and DELETE removes. Status codes show the result: 2xx means success, 401 means not authenticated and 404 means not found.",
		"ex": "Example: POST an incident summary to an external system and check for a 201 response.",
		"qs": [
			{"q": "Which HTTP method normally creates a new record?", "o": ["GET", "POST", "DELETE", "HEAD"], "a": 1, "why": "POST is used to create."},
			{"q": "A call returns 404. What does it mean?", "o": ["Success", "Not authenticated", "Resource not found", "Created"], "a": 2, "why": "404 means the resource was not found."}]},
	]

static func interview() -> Array:
	return [
		{"q": "Explain the difference between an incident and a problem.", "a": "An incident is a service interruption that must be restored. A problem is the underlying cause of one or more incidents. Incidents are fixed fast; problems are investigated to stop repeats."},
		{"q": "What is a Business Rule, and when do you use before versus after?", "a": "Server-side logic that runs on database operations. Use before to change values on the record being saved. Use after to act on related records or start follow-up work once saved."},
		{"q": "How does GlideRecord work?", "a": "Create it for a table, add query conditions, call query(), then loop with next() and read fields. It runs server-side, so limit queries for performance."},
		{"q": "Why is the CMDB important?", "a": "It is a trusted map of CIs and relationships, so you can assess impact, judge change risk and diagnose incidents faster. It only helps if the data is accurate and maintained."},
		{"q": "How do you decide between a catalog request and an incident?", "a": "If something is broken or degraded, it is an incident. If the user wants something new or standard, such as access or equipment, it is a request."},
		{"q": "Design a REST integration that sends incident data to an external system.", "a": "Trigger on a condition, build the payload, send an authenticated POST, handle the response and errors, log the result, and retry or alert on failure. Keep credentials in secure connection records, never in scripts."},
	]

static func game() -> Array:
	return [
		{"d": "The payment service is down for 500 users and business impact is high. What is the best first action?", "o": ["Wait until the next business day", "Treat it as a major incident and engage the on-call team", "Close it as a duplicate"], "a": 1, "why": "High impact and urgency need an immediate, coordinated response."},
		{"d": "An employee emails asking for a new laptop. Which record fits best?", "o": ["Incident", "Problem", "Service request"], "a": 2, "why": "A laptop is something requested, not a service failure."},
		{"d": "The same login failure was logged 20 times this week and nobody knows why. What next?", "o": ["Open a problem record to find the root cause", "Ignore it", "Delete the incidents"], "a": 0, "why": "Repeated incidents with an unknown cause are handled through problem management."},
		{"d": "The team wants to change a production firewall rule next week. Which process?", "o": ["Incident management", "Change management with risk review and approval", "Knowledge management"], "a": 1, "why": "Production changes need assessment and approval to reduce risk."},
	]
