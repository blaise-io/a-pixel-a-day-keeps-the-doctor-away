echo "Running commit.sh..."

dir=$1
file=$2
message=$3

cd "$dir"
git add "$file"
git commit -m "$message" --author="blaisekal+dummy@gmail.com"
git push
