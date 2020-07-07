#!/bin/sh -l

git_setup() {
  cat <<- EOF > $HOME/.netrc
		machine github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
		machine api.github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
EOF
  chmod 600 $HOME/.netrc

  git config --global user.email "$GITBOT_EMAIL"
  git config --global user.name "$GITHUB_ACTOR"
}

git_cmd() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo $@
  else
    eval $@
  fi
}

PR_BRANCH="auto-$GITHUB_SHA"
MESSAGE=$(git log -1 --format="%s" $GITHUB_SHA)

if [[ $MESSAGE =~ "AUTO" ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

ALLOW_MERGES=''
if [[ ${INPUT_ALLOW_MERGES} == 'true' ]]; then
  ALLOW_MERGES='-m'
fi

git_setup
git_cmd git remote update
git_cmd git fetch --all
git_cmd git checkout -b "${PR_BRANCH}" origin/"${INPUT_PR_BRANCH}"
git_cmd git push -u origin "${PR_BRANCH}"
git_cmd git cherry-pick ${ALLOW_MERGES} "${GITHUB_SHA}"
git_cmd git push
git_cmd hub pull-request -b "${INPUT_PR_BRANCH}" -h "${PR_BRANCH}" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "\"AUTO: ${MESSAGE}\""
