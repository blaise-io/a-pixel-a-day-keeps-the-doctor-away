dir=$1
file=$2
message=$3

cd "$dir"

echo "Committing..."
git add "$file"
git commit -m "$message" --author="blaisekal+dummy@gmail.com"

echo "Pushing..."
git push
