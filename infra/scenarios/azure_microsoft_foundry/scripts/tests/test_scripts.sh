#!/bin/sh

set -eu

TEST_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
SCRIPT_DIR=$(CDPATH='' cd "${TEST_DIR}/.." && pwd)
FIXTURE=$(mktemp -d "${TMPDIR:-/tmp}/foundry-tests.XXXXXX")
mkdir "${FIXTURE}/bin"
trap 'rm -rf "$FIXTURE"' 0
trap 'exit 1' HUP INT TERM
export FIXTURE

PATH="${FIXTURE}/bin:${PATH}"
export PATH

cat > "${FIXTURE}/bin/terraform" <<'EOF'
#!/bin/sh
case "$*" in
  *" output -json")
    cat <<'JSON'
{
  "resource_group_name": {"value": "rg-foundry-test"},
  "microsoft_foundry_account_name": {"value": "foundry-test"},
  "microsoft_foundry_openai_endpoint": {"value": "https://foundry-test.openai.azure.com/"},
  "microsoft_foundry_project_id": {"value": "/subscriptions/sub-123/resourceGroups/rg-foundry-test/providers/Microsoft.CognitiveServices/accounts/foundry-test/projects/project-test"},
  "microsoft_foundry_project_name": {"value": "project-test"},
  "microsoft_foundry_project_endpoint": {"value": "https://foundry-test.services.ai.azure.com/api/projects/project-test"},
  "microsoft_foundry_deployment_ids": {
    "value": {
      "gpt-5.4-mini": "/deployments/gpt-5.4-mini",
      "text-embedding-3-large": "/deployments/text-embedding-3-large"
    }
  },
  "azure_ai_search_id": {"value": "/subscriptions/sub-123/resourceGroups/rg-foundry-test/providers/Microsoft.Search/searchServices/search-test"},
  "azure_ai_search_name": {"value": "search-test"},
  "azure_ai_search_endpoint": {"value": "https://search-test.search.windows.net"},
  "blob_storage_account_id": {"value": "/subscriptions/sub-123/resourceGroups/rg-foundry-test/providers/Microsoft.Storage/storageAccounts/storage-test"},
  "blob_storage_account_name": {"value": "storagetest"},
  "blob_storage_endpoint": {"value": "https://storagetest.blob.core.windows.net/"},
  "operator_principal_id": {"value": "00000000-0000-0000-0000-000000000004"}
}
JSON
    ;;
  *) exit 1 ;;
esac
EOF

cat > "${FIXTURE}/bin/az" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${FIXTURE}/az.calls"
case "$*" in
  *"account get-access-token"*)
    printf '%s\n' "offline-token"
    ;;
  *"account show"*)
    :
    ;;
  *)
    exit 1
    ;;
esac
EOF

cat > "${FIXTURE}/bin/sleep" <<'EOF'
#!/bin/sh
:
EOF

cat > "${FIXTURE}/bin/curl" <<'EOF'
#!/bin/sh
body_file=""
data=""
authorization=""
method="GET"
url=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      body_file=$2
      shift
      ;;
    --request)
      method=$2
      shift
      ;;
    --data)
      data=$2
      shift
      ;;
    --header)
      case "$2" in
        Authorization:*) authorization=${2#Authorization: } ;;
      esac
      shift
      ;;
    --data-binary|--write-out)
      shift
      ;;
    http://*|https://*)
      url=$1
      ;;
  esac
  shift
done

[ -n "$body_file" ] || exit 1
[ "$authorization" = "Bearer offline-token" ] || {
  printf 'Unexpected Authorization header for %s %s\n' "$method" "$url" >&2
  exit 1
}
printf '%s|%s|%s\n' "${MOCK_CASE:-}" "$method" "$url" >> "${FIXTURE}/curl.calls"
if [ -n "$data" ]; then
  printf '%s\n' "$data" >> "${FIXTURE}/curl.data"
fi

status=500
body='{"error":{"code":"UnexpectedRequest","message":"Unexpected mock request"}}'

case "${MOCK_CASE:-}:$method:$url" in
  full-run:PUT:*"?restype=container")
    status=201
    body=''
    ;;
  full-run:PUT:*"/restaurant_reviews.csv")
    status=201
    body=''
    ;;
  full-run:PUT:*"/knowledgesources('restaurant-reviews-ks')"*)
    status=201
    body='{"name":"restaurant-reviews-ks","azureBlobParameters":{"createdResources":{"indexer":"restaurant-reviews-ks-indexer"}}}'
    ;;
  ingestion-fresh:GET:*"/knowledgesources('restaurant-reviews-ks')/status"*|full-run:GET:*"/knowledgesources('restaurant-reviews-ks')/status"*)
    count=0
    [ ! -f "${FIXTURE}/status.count" ] || count=$(cat "${FIXTURE}/status.count")
    count=$((count + 1))
    printf '%s\n' "$count" > "${FIXTURE}/status.count"
    status=200
    if [ "$count" -eq 1 ]; then
      body='{"synchronizationStatus":"idle","lastSynchronizationState":{"startTime":"2026-09-30T00:00:00Z","endTime":"2026-09-30T00:00:05Z","itemsUpdatesProcessed":1,"itemsUpdatesFailed":0}}'
    else
      body='{"synchronizationStatus":"idle","lastSynchronizationState":{"startTime":"2026-09-30T00:01:00Z","endTime":"2026-09-30T00:01:05Z","itemsUpdatesProcessed":1,"itemsUpdatesFailed":0}}'
    fi
    ;;
  ingestion-fresh:GET:*"/knowledgesources('restaurant-reviews-ks')"*|full-run:GET:*"/knowledgesources('restaurant-reviews-ks')"*)
    status=200
    body='{"name":"restaurant-reviews-ks","azureBlobParameters":{"createdResources":{"indexer":"restaurant-reviews-ks-indexer"}}}'
    ;;
  ingestion-fresh:POST:*"/indexers('restaurant-reviews-ks-indexer')/search.run"*|full-run:POST:*"/indexers('restaurant-reviews-ks-indexer')/search.run"*)
    status=202
    body=''
    ;;
  full-run:PUT:*"/knowledgebases('restaurant-reviews-kb')"*)
    status=201
    body='{"name":"restaurant-reviews-kb"}'
    ;;
  retrieval-success:POST:*"/knowledgebases('restaurant-reviews-kb')/retrieve"*|full-run:POST:*"/knowledgebases('restaurant-reviews-kb')/retrieve"*)
    status=206
    body='{"response":[{"content":[{"type":"text","text":"Grounded vegan result"}]}],"references":[{"type":"azureBlob","blobUrl":"https://example/reviews.csv","rerankerScore":3.2}],"activity":[]}'
    ;;
  retrieval-no-references:POST:*"/knowledgebases('restaurant-reviews-kb')/retrieve"*)
    status=200
    body='{"response":[{"content":[{"type":"text","text":"Ungrounded result"}]}],"references":[]}'
    ;;
  full-run:PUT:*/connections/restaurant-reviews-kb-mcp*)
    status=201
    body='{"name":"restaurant-reviews-kb-mcp"}'
    ;;
  full-run:POST:*/agents*)
    status=201
    body='{"name":"restaurant-qa-agent","version":"1"}'
    ;;
  agent-success:POST:*/openai/v1/conversations|full-run:POST:*/openai/v1/conversations)
    status=201
    if [ "${MOCK_CASE:-}" = "full-run" ]; then
      body='{"id":"conv-full-run"}'
    else
      body='{"id":"conv-success"}'
    fi
    ;;
  agent-success:POST:*/openai/v1/responses|full-run:POST:*/openai/v1/responses)
    status=200
    body='{"output_text":"Grounded agent answer","output":[{"type":"mcp_call"}]}'
    ;;
  agent-success:DELETE:*/openai/v1/conversations/conv-success|full-run:DELETE:*/openai/v1/conversations/conv-full-run)
    status=204
    body=''
    ;;
  agent-no-mcp:POST:*/openai/v1/conversations)
    status=201
    body='{"id":"conv-no-mcp"}'
    ;;
  agent-no-mcp:POST:*/openai/v1/responses)
    status=200
    body='{"output_text":"Answer without a tool call","output":[{"type":"message"}]}'
    ;;
  agent-no-mcp:DELETE:*/openai/v1/conversations/conv-no-mcp)
    status=204
    body=''
    ;;
  cleanup:DELETE:*)
    status=204
    body=''
    ;;
  cleanup:GET:*"/knowledgebases('restaurant-reviews-kb')"*|cleanup:GET:*"/knowledgesources('restaurant-reviews-ks')"*)
    status=404
    body='{"error":{"code":"NotFound"}}'
    ;;
esac

printf '%s' "$body" > "$body_file"
printf '%s' "$status"
EOF

chmod +x "${FIXTURE}/bin/"*

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" > "${FIXTURE}/stdout" 2> "${FIXTURE}/stderr"; then
    fail "Expected failure: $*"
  fi
}

reset_case() {
  rm -f "${FIXTURE}/curl.calls" "${FIXTURE}/curl.data" "${FIXTURE}/status.count" "${FIXTURE}/stdout" "${FIXTURE}/stderr"
}

DEFAULTS=$(
  # shellcheck disable=SC1091
  . "${SCRIPT_DIR}/_common.sh"
  printf '%s|%s|%s|%s' "$SEARCH_API_VERSION" "$STORAGE_API_VERSION" "$KEEP_CONVERSATION" "$AGENT_MODEL"
)
[ "$DEFAULTS" = "2026-08-01-preview|2026-04-06|false|gpt-5.4-mini" ] ||
  fail "Unexpected common defaults: ${DEFAULTS}"

reset_case
TOKEN_OUTPUT=$(
  (
    # shellcheck disable=SC1091
    . "${SCRIPT_DIR}/_common.sh"
    VERBOSE_OUTPUT=true
    AZURE_SUBSCRIPTION_ID=sub-123
    export VERBOSE_OUTPUT AZURE_SUBSCRIPTION_ID
    get_access_token "https://search.azure.com/.default"
  ) 2> "${FIXTURE}/stderr"
)
[ "$TOKEN_OUTPUT" = "offline-token" ] ||
  fail "Verbose logging contaminated the access token value."
grep -q "\[verbose\] Requesting an Azure access token" "${FIXTURE}/stderr" ||
  fail "Verbose access-token progress was not reported."

if (
  # shellcheck disable=SC1091
  . "${SCRIPT_DIR}/_common.sh"
  validate_boolean TEST maybe
) >/dev/null 2>&1; then
  fail "Invalid boolean value was accepted."
fi

reset_case
MOCK_CASE=ingestion-fresh
export MOCK_CASE
"${SCRIPT_DIR}/03_wait_for_ingestion.sh" > "${FIXTURE}/stdout" ||
  fail "Fresh ingestion workflow failed."
grep -q "/search.run" "${FIXTURE}/curl.calls" ||
  fail "Stale completed ingestion was accepted without starting a fresh run."
grep -q "2026-09-30T00:01:00Z completed successfully" "${FIXTURE}/stdout" ||
  fail "Fresh ingestion completion was not reported."

reset_case
MOCK_CASE=retrieval-success
export MOCK_CASE
"${SCRIPT_DIR}/05_retrieve_knowledge_base.sh" > "${FIXTURE}/stdout" ||
  fail "Partial retrieval with grounding references failed."
grep -q "partial content" "${FIXTURE}/stdout" ||
  fail "Partial retrieval response was not surfaced."
grep -q "References (1)" "${FIXTURE}/stdout" ||
  fail "Grounding reference count was not reported."

reset_case
MOCK_CASE=retrieval-no-references
export MOCK_CASE
expect_failure "${SCRIPT_DIR}/05_retrieve_knowledge_base.sh"
grep -q "no grounding references" "${FIXTURE}/stderr" ||
  fail "Missing grounding references did not produce a clear failure."

reset_case
MOCK_CASE=agent-success
export MOCK_CASE
"${SCRIPT_DIR}/08_ask_agent.sh" > "${FIXTURE}/stdout" ||
  fail "Grounded agent response workflow failed."
grep -q "MCP events: 1" "${FIXTURE}/stdout" ||
  fail "MCP event count was not reported."
grep -q "DELETE|https://foundry-test.services.ai.azure.com/api/projects/project-test/openai/v1/conversations/conv-success" "${FIXTURE}/curl.calls" ||
  fail "Transient conversation was not deleted after success."

reset_case
MOCK_CASE=agent-success
export MOCK_CASE
QUESTION="Which restaurant has patio seating?" \
  "${SCRIPT_DIR}/08_ask_agent.sh" --verbose > "${FIXTURE}/stdout" 2> "${FIXTURE}/stderr" ||
  fail "QUESTION environment override with --verbose failed."
grep -q "Which restaurant has patio seating?" "${FIXTURE}/curl.data" ||
  fail "QUESTION environment override was not sent to the agent."
grep -q "\[verbose\] HTTP request: POST https://foundry-test.services.ai.azure.com/api/projects/project-test/openai/v1/responses" "${FIXTURE}/stdout" ||
  fail "Verbose HTTP request progress was not reported."
grep -q "\[verbose\] HTTP response: 200 POST https://foundry-test.services.ai.azure.com/api/projects/project-test/openai/v1/responses" "${FIXTURE}/stdout" ||
  fail "Verbose HTTP response status was not reported."
if grep -q "offline-token" "${FIXTURE}/stdout" ||
  { [ -f "${FIXTURE}/stderr" ] && grep -q "offline-token" "${FIXTURE}/stderr"; }; then
  fail "Verbose output exposed an access token."
fi

reset_case
MOCK_CASE=agent-success
export MOCK_CASE
QUESTION="Environment question" \
  "${SCRIPT_DIR}/08_ask_agent.sh" "Positional question" > "${FIXTURE}/stdout" ||
  fail "Positional question compatibility failed."
grep -q "Positional question" "${FIXTURE}/curl.data" ||
  fail "Positional question was not sent to the agent."
if grep -q "Environment question" "${FIXTURE}/curl.data"; then
  fail "Environment question incorrectly overrode the positional question."
fi

reset_case
MOCK_CASE=agent-no-mcp
export MOCK_CASE
expect_failure "${SCRIPT_DIR}/08_ask_agent.sh"
grep -q "did not contain an MCP tool event" "${FIXTURE}/stderr" ||
  fail "Missing MCP event did not fail the verification gate."
grep -q "DELETE|https://foundry-test.services.ai.azure.com/api/projects/project-test/openai/v1/conversations/conv-no-mcp" "${FIXTURE}/curl.calls" ||
  fail "Transient conversation was not deleted after a failed verification gate."

reset_case
MOCK_CASE=cleanup
export MOCK_CASE
CONFIRM_CLEANUP=delete-foundry-iq-resources \
  "${SCRIPT_DIR}/09_cleanup.sh" --verbose > "${FIXTURE}/stdout" 2> "${FIXTURE}/stderr" ||
  fail "Cleanup workflow with --verbose failed."
grep -q "GET|https://search-test.search.windows.net/knowledgebases('restaurant-reviews-kb')" "${FIXTURE}/curl.calls" ||
  fail "Cleanup did not confirm knowledge base deletion."
grep -q "GET|https://search-test.search.windows.net/knowledgesources('restaurant-reviews-ks')" "${FIXTURE}/curl.calls" ||
  fail "Cleanup did not confirm knowledge source deletion."
grep -q "script-created resources were cleaned up" "${FIXTURE}/stdout" ||
  fail "Cleanup success was not reported."
grep -q "\[verbose\] HTTP response: 404 GET https://search-test.search.windows.net/knowledgesources('restaurant-reviews-ks')" "${FIXTURE}/stdout" ||
  fail "Cleanup verbose HTTP status was not reported."

reset_case
MOCK_CASE=full-run
export MOCK_CASE
"${SCRIPT_DIR}/run_all.sh" --verbose > "${FIXTURE}/stdout" 2> "${FIXTURE}/stderr" ||
  fail "run_all.sh did not complete with --verbose."
for message in \
  "Validating local tools, Terraform outputs, models, Azure login, and token audiences." \
  "Preparing the private Blob container and restaurant review upload." \
  "Preparing the keyless Azure Blob knowledge source." \
  "Checking for a fresh knowledge source ingestion run." \
  "Preparing the extractive knowledge base." \
  "Preparing direct knowledge base retrieval." \
  "Preparing the managed-identity RemoteTool project connection." \
  "Preparing a new MCP-enabled prompt-agent version." \
  "Preparing a conversation and grounded prompt-agent request."
do
  grep -Fq "[verbose] ${message}" "${FIXTURE}/stdout" ||
    fail "run_all.sh did not propagate --verbose for: ${message}"
done
grep -q "All Microsoft Foundry scenario checks passed." "${FIXTURE}/stdout" ||
  fail "run_all.sh did not report successful completion."
if grep -q "offline-token" "${FIXTURE}/stdout" "${FIXTURE}/stderr"; then
  fail "run_all.sh --verbose exposed an access token."
fi

printf '%s\n' "Offline Microsoft Foundry script checks passed."
