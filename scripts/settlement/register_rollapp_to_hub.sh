#!/bin/bash

# this account must be whitelisted on the hub for permissioned deployment setup
DEPLOYER=${HUB_PERMISSIONED_KEY-"$HUB_KEY_WITH_FUNDS"}

if [ "$EXECUTABLE" = "" ]; then
  DEFAULT_EXECUTABLE=$(which dymd)

  if [ "$DEFAULT_EXECUTABLE" = "" ]; then
    echo "dymd not found in PATH. Exiting."
    exit 1
  fi
  echo "EXECUTABLE is not set, using '${DEFAULT_EXECUTABLE}'"
  EXECUTABLE=$DEFAULT_SEQUENCER_KEY_PATH
fi

if [ "$BECH32_PREFIX" = "" ]; then
  echo "BECH32_PREFIX is not set, exiting "
  exit 1
fi

if [ "$SEQUENCER_KEY_PATH" = "" ]; then
  DEFAULT_SEQUENCER_KEY_PATH="${ROLLAPP_HOME_DIR}/sequencer_keys"
  echo "SEQUENCER_KEY_PATH is not set, using '${DEFAULT_SEQUENCER_KEY_PATH}'"
  SEQUENCER_KEY_PATH=$DEFAULT_SEQUENCER_KEY_PATH
fi

if [ "$SEQUENCER_KEY_NAME" = "" ]; then
  DEFAULT_SEQUENCER_KEY_NAME="sequencer"
  echo "SEQUENCER_KEY_NAME is not set, using '${DEFAULT_SEQUENCER_KEY_NAME}'"
  SEQUENCER_KEY_NAME=$DEFAULT_SEQUENCER_KEY_NAME
fi

if [ "$ROLLAPP_ALIAS" = "" ]; then
  DEFAULT_ALIAS="${ROLLAPP_CHAIN_ID%%_*}"
  echo "ROLLAPP_ALIAS is not set, using '$DEFAULT_ALIAS'"
  ROLLAPP_ALIAS=$DEFAULT_ALIAS
fi

if [ "$ROLLAPP_HOME_DIR" = "" ]; then
  DEFAULT_ROLLAPP_HOME_DIR=${HOME}/.rollapp_evm
  echo "DEFAULT_ROLLAPP_HOME_DIR is not set, using '$DEFAULT_ROLLAPP_HOME_DIR'"
  ROLLAPP_HOME_DIR=$DEFAULT_ROLLAPP_HOME_DIR
fi

if [ "$NATIVE_DENOM_PATH" = "" ]; then
  DEFAULT_NATIVE_DENOM_PATH="${ROLLAPP_HOME_DIR}/init/rollapp-native-denom.json"
  echo "NATIVE_DENOM_PATH is not set, using '$DEFAULT_NATIVE_DENOM_PATH"
  NATIVE_DENOM_PATH=$DEFAULT_NATIVE_DENOM_PATH

  if [ ! -f "$NATIVE_DENOM_PATH" ]; then
    echo "${NATIVE_DENOM_PATH} does not exist, would you like to create native-denom file? (y/n)"
    read -r answer

    if [ "$answer" != "${answer#[Yy]}" ]; then
      cat <<EOF > "$NATIVE_DENOM_PATH"
{
  "display": "$DENOM",
  "base": "$BASE_DENOM",
  "exponent": 18
}
EOF
    else
      echo "You can't register a rollapp without a native denom, please create the ${NATIVE_DENOM_PATH} and run the script again"
      exit 1
    fi
  fi
fi

GENESIS_PATH="${ROLLAPP_HOME_DIR}/config/genesis.json"
GENESIS_HASH=$(sha256sum "$GENESIS_PATH" | awk '{print $1}' | sed 's/[[:space:]]*$//')
#GENESIS_HASH="PLACEHOLDER"

INITIAL_SUPPLY=$(jq -r '.app_state.bank.supply[0].amount' "${ROLLAPP_HOME_DIR}/config/genesis.json")

if [ "$SETTLEMENT_EXECUTABLE" = "" ]; then
  DEFAULT_SETTLEMENT_EXECUTABLE=$(which dymd)
  echo "SETTLEMENT_EXECUTABLE is not set, using '${SETTLEMENT_EXECUTABLE}'"
  SETTLEMENT_EXECUTABLE=$DEFAULT_SETTLEMENT_EXECUTABLE

  if [ "$SETTLEMENT_EXECUTABLE" = "" ]; then
    echo "dymension binary not found in PATH. Exiting."
    exit 1
  fi
fi

METADATA_PATH="${ROLLAPP_HOME_DIR}/init/rollapp-metadata.json"

if [ ! -f "$METADATA_PATH" ]; then
  echo "${METADATA_PATH} does not exist, creating default metadata file"
  cat <<EOF > "$METADATA_PATH"
{
   "description": "",
  "display_name": "",
  "explorer_url": "",
  "fee_denom": null,
  "genesis_url": "http://localhost:26657/genesis",
  "logo_url": "",
  "tagline": "",
  "telegram": "",
  "website": "",
  "x": ""
}
EOF
fi

set -x
"$SETTLEMENT_EXECUTABLE" tx rollapp create-rollapp "$ROLLAPP_CHAIN_ID" "$ROLLAPP_ALIAS" EVM \
  --bech32-prefix "$BECH32_PREFIX" \
  --init-sequencer "*" \
  --genesis-checksum "$GENESIS_HASH" \
  --native-denom "$NATIVE_DENOM_PATH" \
  --initial-supply "$INITIAL_SUPPLY" \
  --from "$DEPLOYER" \
  --keyring-backend test \
  --gas auto --gas-adjustment 1.2 \
  --metadata "$METADATA_PATH" \
  --fees 1dym
set +x