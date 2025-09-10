INITIAL_WITNESS_PORT=5642
WITNESS_COUNT=6
NAMESPACE=${1:-cf-idw}
TLD=${2:-example.cf-deployments.org}

WITNESSES_URLS=""
for seq in $(seq 0 $((WITNESS_COUNT - 1)));
do
  while [[ -z "$WITNESS_OOBI" ]]; do
    WITNESS_OOBI=$(kubectl logs -n ${NAMESPACE} witness-$seq-0 2>/dev/null | grep ^Witness | awk '{print $NF}')
    sleep 1
  done
  WITNESS_PORT=$((INITIAL_WITNESS_PORT + seq))
  WITNESSES_URLS="${WITNESSES_URLS#^ } http://witness-$seq.${TLD}/oobi/${WITNESS_OOBI}/controller?role=witness"
  unset WITNESS_OOBI
done

echo $WITNESSES_URLS
