#! /bin/zsh
#
# Re-tags the fidesdemo main branch to have 7 commits, tagged in order.
# This does a destructive `push -f` so it should probably be replaced in
# the future, but right now it feels easier for new contributors to be
# able to follow along in our tutorials using git tags.

if [[ $(git rev-list HEAD --count) != "7" ]]
then
  echo "Unable to automatically retag; start by interactively rebasing and squashing down to exactly 7 commits!"
  echo "Use 'git rebase -i --root' to edit/squash commits as needed first"
  exit 0
fi

echo "Deleting existing tags..."
git tag -d fidesops-demo fidesops-start fidesctl-demo fidesctl-add-google-analytics fidesctl-manifests fidesctl-start tutorial-start

echo "Retagging commits..."
git tag fidesops-demo
git checkout HEAD^1
git tag fidesops-start
git checkout HEAD^1
git tag fidesctl-demo
git checkout HEAD^1
git tag fidesctl-add-google-analytics
git checkout HEAD^1
git tag fidesctl-manifests
git checkout HEAD^1
git tag fidesctl-start
git checkout HEAD^1
git tag tutorial-start
git checkout main

echo "Done! Check tags:"
git log --oneline

echo ""
echo "Use 'git push -f --tags' to push to remote"
