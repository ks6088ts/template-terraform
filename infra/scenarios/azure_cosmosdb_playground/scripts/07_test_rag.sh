#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens
seed_documents
embed "What is the Cosmos DB change feed?"
query=$(tagged_query \
  'SELECT TOP 3 c.id, c.content FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag ORDER BY RANK RRF(VectorDistance(c.embedding, @vector), FullTextScore(c.content, @term))' \
  "$(jq -nc --argjson vector "$EMBEDDING" --arg term "change feed" \
    '[{name:"@vector",value:$vector},{name:"@term",value:$term}]')")
wait_query_documents "$query"
context=$(printf '%s' "$HTTP_BODY" | jq -r '[.Documents[]? | "\(.id): \(.content)"] | join("\n")')
retrieved_ids=$(printf '%s' "$HTTP_BODY" | jq -c '[.Documents[]?.id]')
[ -n "$context" ] || die "No retrieval context for RAG"
get_foundry_token
payload=$(jq -nc --arg context "$context" --arg model "$CHAT_DEPLOYMENT_NAME" \
  '{model:$model,messages:[{role:"system",content:"Answer only from the supplied context; cite document IDs. If unknown, say so."},{role:"user",content:("Context:\n"+$context+"\n\nQuestion: What is the Cosmos DB change feed?")}],max_completion_tokens:2000}')
foundry_request POST "openai/v1/chat/completions" --data "$payload"
expect_status 200
answer=$(printf '%s' "$HTTP_BODY" | jq -er '.choices[0].message.content | select(type == "string" and length > 0)') || die "No chat response"
printf '%s' "$retrieved_ids" | jq -e --arg answer "$answer" \
  'any(.[]; . as $id | $answer | contains($id))' >/dev/null || die "RAG answer omitted all retrieved document IDs"
printf '%s\n' "$answer"
