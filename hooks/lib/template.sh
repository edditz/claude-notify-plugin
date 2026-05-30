#!/bin/bash

# Template and variable replacement module

# Get project directory name
get_project_name() {
    basename "$(pwd)"
}

# Replace variables in template
replace_variables() {
    local template="$1"
    local project_name
    project_name=$(get_project_name)

    # Replace {project_name} with actual project name
    echo "${template//\{project_name\}/$project_name}"
}

# Build notification for PermissionRequest event
build_permission_notification() {
    local input="$1"

    # Extract tool name from input
    local tool_name
    tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)

    # Get title and body templates (with defaults)
    local title_template="${NTFY_PERMISSION_TITLE:-Claude 需要审批}"
    local body_template="${NTFY_PERMISSION_BODY:-{tool_name}}"

    # Replace variables
    local title
    title=$(replace_variables "$title_template")
    local body
    body=$(replace_variables "$body_template")

    # Replace {tool_name} with actual tool name
    body="${body//\{tool_name\}/$tool_name}"

    # Output: title|body|priority|tags
    echo "${title}|${body}|4|bell"
}

# Build notification for Stop event
build_stop_notification() {
    local input="$1"

    # Extract message from input
    local message
    message=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
msg = d.get('last_assistant_message','')
print(msg[:100]) if msg else print('')
" 2>/dev/null)

    # Get title and body templates (with defaults)
    local title_template="${NTFY_STOP_TITLE:-Claude 已停止}"
    local body_template="${NTFY_STOP_BODY:-{message}}"

    # Replace variables
    local title
    title=$(replace_variables "$title_template")
    local body
    body=$(replace_variables "$body_template")

    # Replace {message} with actual message
    body="${body//\{message\}/$message}"

    # Output: title|body|priority|tags
    echo "${title}|${body}|3|check"
}
