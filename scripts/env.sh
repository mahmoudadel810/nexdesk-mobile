# Puts Flutter, Java and the Android tools on PATH. Uses the versions in ~/dev-tools when they are there
# (see README), so the scripts work without changing the shell profile.
TOOLS="${NEXDESK_TOOLS:-$HOME/dev-tools}"
if [[ -d "$TOOLS/flutter/bin" ]]; then
  export PATH="$TOOLS/flutter/bin:$PATH"
fi
if [[ -d "$TOOLS/jdk-17" ]]; then
  export JAVA_HOME="$TOOLS/jdk-17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
if [[ -d "$TOOLS/android-sdk" ]]; then
  export ANDROID_HOME="$TOOLS/android-sdk"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
if [[ -d "$HOME/.maestro/bin" ]]; then
  export PATH="$HOME/.maestro/bin:$PATH"
fi
