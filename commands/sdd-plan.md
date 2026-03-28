---
description: Analyze spec + tasks + design and produce an impact/scope plan before implementation
agent: sdd-orchestrator
---

Follow the SDD orchestrator workflow to create an implementation plan for change "$ARGUMENTS".

WORKFLOW:
1. Launch sdd-plan sub-agent to analyze spec, tasks, and design
2. Present the plan summary to the user
3. Wait for user confirmation before proceeding to sdd-apply

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Change name: $ARGUMENTS
- Artifact store mode: engram

ENGRAM NOTE:
Sub-agents handle persistence automatically. Each phase saves its artifact to engram with topic_key "sdd/$ARGUMENTS/{type}".

Read the orchestrator instructions to coordinate this workflow. Do NOT execute phase work inline — delegate to sub-agents.
