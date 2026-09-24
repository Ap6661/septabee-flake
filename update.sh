
if [[ $# -lt 1 ]]; then
  echo "Missing Version"
  echo $#
  exit 1
fi

V=$1;
Vo=$V"_offline";

NORMAL=$(nix-prefetch-url \
  "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_$V.7z" \
  --type sha256 2> /dev/null | xargs nix-hash --type sha256 --to-base64)

OFFLINE=$(nix-prefetch-url \
  "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_$Vo.7z" \
  --type sha256 2> /dev/null | xargs nix-hash --type sha256 --to-base64)

# echo $NORMAL
# echo $OFFLINE

# Remove any existing 
sed ./versions.nix -e "/\"$V\"/d" -i 
sed ./versions.nix -e "/\"$Vo\"/d" -i

# Remove Latest
sed ./versions.nix -e "/latest/d" -i 

# Add hash to top
sed ./versions.nix -e "s:\(hashes = {\):\1\n    \"$Vo\" = \"sha256-$OFFLINE\";:" -i 
sed ./versions.nix -e "s:\(hashes = {\):\1\n    \"$V\" = \"sha256-$NORMAL\";:" -i 

# Update Latest
sed ./versions.nix -e "2i \ \ latest = \"$V\";" -i 
sed ./versions.nix -e "3i \ \ latest_offline = \"$Vo\";" -i

# Show your changes
cat ./versions.nix

if [[ $# == 2 ]]; then
  echo Building... 
  nix build ".#septabee-$V" -o online
  nix build ".#septabee-$Vo" -o offline

  echo Testing Onine Version... 
  ./online/bin/septabee

  echo Testing Offline Version... 
  ./offline/bin/septabee
fi
