dir=$1
repository=$2
email=$3
username=$4

git clone $repository $dir
git config user.email "$email"
git config user.name "$username"
