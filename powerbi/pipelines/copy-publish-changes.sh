git diff HEAD~1 HEAD~0 --diff-filter=d --name-only > Artefact.txt #diff filter is deselecting deleted files
echo "---Files added to artefacts---"
cat Artefact.txt
mkdir "$(Build.ArtifactStagingDirectory)/Artefact"
while IFS= read -r Artefact; do
  cp --parents "./$Artefact" "$(Build.ArtifactStagingDirectory)/Artefact"  #copy with complete path
done < Artefact.txt