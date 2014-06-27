echo "Running setup.sh..."

dir=$1
repository=$2
email=$3
name=$4

git clone $repository $dir
git push --set-upstream origin master
cd $dir
git config user.email "$email"
git config user.name "$name"
