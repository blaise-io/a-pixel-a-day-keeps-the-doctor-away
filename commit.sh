echo "Running commit.sh..."

dir=$1
file=$2
message=$3

cd "$dir"
git add "$file"
git commit -m "$message"
git push
