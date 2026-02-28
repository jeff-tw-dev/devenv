#!/bin/zsh

# Configuration
USER_NAME="Openclaw"
KEYCHAIN="openclaw"

# 2. Google Maps Platform API Key
# Maps usually expects a raw API key string, not a JSON file path.
MAPS_KEY=$(security find-generic-password -a ${USER_NAME} -s google-map-api-key -w ${KEYCHAIN})
if [ -n "$MAPS_KEY" ]; then
    export GOOGLE_PLACES_API_KEY="$MAPS_KEY"
    echo "✅ Google Maps API key setup"
fi

# 3. Gemini API Key
GEMINI_KEY=$(security find-generic-password -a ${USER_NAME} -s gemini-api-key -w ${KEYCHAIN})
if [ -n "$GEMINI_KEY" ]; then
    # Note: Many SDKs use GOOGLE_API_KEY or GEMINI_API_KEY
    export GEMINI_API_KEY="$GEMINI_KEY"
    echo "✅ Gemini API key setup"
fi

# 4. Openrouter API Key
OPENROUTER_KEY=$(security find-generic-password -a ${USER_NAME} -s openrouter-api-key -w ${KEYCHAIN})
if [ -n "$OPENROUTER_KEY" ]; then
    export OPENROUTER_API_KEY="$OPENROUTER_KEY"
    echo "✅ OpenRouter API key setup"
fi

# 4. AWS Credentials
# AWS is best handled by setting the profile name or raw keys.
AWS_ACCESS=$(security find-generic-password -a ${USER_NAME} -s aws-access-key -w ${KEYCHAIN})
AWS_SECRET=$(security find-generic-password -a ${USER_NAME} -s aws-secret-key -w ${KEYCHAIN})

if [ -n "$AWS_ACCESS" ] && [ -n "$AWS_SECRET" ]; then
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET"
    export AWS_REGION="ap-southeast-2" # Sydney
    echo "✅ AWS credentials setup"
fi

FINNHUB_KEY=$(security find-generic-password -a ${USER_NAME} -s finnhub-api-key -w ${KEYCHAIN})
if [ -n "$FINNHUB_KEY" ]; then
    export FINNHUB_API_KEY="$FINNHUB_KEY"
    echo "✅ Finnhub API key setup"
fi

# Run the application
# echo "🚀 Starting Openclaw..."
if [ -n "$1" ]; then
    /Users/luca/.nvm/versions/node/v24.13.1/bin/openclaw "$@"
fi
