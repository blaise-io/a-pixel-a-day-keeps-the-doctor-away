dir=$1
repository=$2
email=$3
name=$4

echo "Cloning..."
git clone $repository $dir
cd $dir

echo "Setting git config..."
git config user.email "$email"
git config user.name "$name"
