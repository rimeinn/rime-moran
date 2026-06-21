# AGENTS.md

## Conventions

- Always consult **rime-workflow** _and_ **rime-gears** skills if available. Even if you think you know Rime, double check! Moran is a set of modern and advanced Rime schemas. You need up-to-date Rime knowledge first to answer questions accurately.
- If user's choice of moran schema is undecided, confirm which schema the user is asking about, and always refer to the documentation.

## Dev environment

- Depends on Python uv.
- If this is a git repo, first check if it's on the main branch. If so, refer to README.md's last section for how to initialize the repo.
- For details, refer to:
  + Setup dev environment: https://zrmfans.cn/book/develop/setup.md
  + Common dev tasks: https://zrmfans.cn/book/develop/cheatsheet.md
  + Schemagen.py usage: https://zrmfans.cn/book/develop/schemagen/index.md

## Documentation

- **summary of files**: https://zrmfans.cn/book/maintenance/files.md
- **schema framework**: https://zrmfans.cn/book/maintenance/config.md
- **moran** options: https://zrmfans.cn/book/usage/features.md
- **moran_fixed** options: https://zrmfans.cn/book/schemas/zici/features.md
- **moran_aux** options: https://zrmfans.cn/book/schemas/fushai/features.md
- **moran_sentence** is a cut-down version of moran, see the yaml file and compare to moran.schema.yaml

## Change workflow

- Prefer minimal source-data edits. For dictionary entries with generated auxiliary-code comments, edit the spelling/code or word form before generated auxiliary data; do not hand-edit generated auxiliary-code fields unless the repository documentation says that field is source data.
- After dictionary/schema source changes, run `make all` from the repository root when practical, then inspect the generated diff. Stop and ask if `make all` produces large unrelated rewrites.
- For destructive or broad changes, such as deleting files, large rewrites, or force-pushing shared branches, ask first.

## Dictionary maintenance notes

- Distinguish **adding/removing a code** from **adding/removing a word**. If a report says a candidate is duplicated or has an extra/wrong code, usually keep the word and only add/remove the specific code unless the issue explicitly asks to remove the word.
- `moran_fixed.dict.yaml` and `moran_fixed_simp.dict.yaml` should normally be updated together. When changing simplified entries, check and apply the corresponding traditional entries too.
- Keep dictionary blocks sorted by the code column. Do not append entries to the end of the file unless that is the correct block and sorted position.
- Respect block boundaries. Three-character words belong in the three-word block, longer phrases in the main phrase block, and special/test blocks should stay separate.
- When editing entries whose code contains a fly-key pattern (`wz -> wk`, `xq -> xo`, `qx -> qo`), update the corresponding fly-key region as well. For example, changing the order of `ihwz` entries also requires checking the generated/parallel `ihwk` entries.
- When adding a new decomposition for a character in `tools/data/moran_chai.txt`, keep existing decompositions unless the issue explicitly says the old decomposition is wrong and should be removed.
- For intelligent/sentence dictionary additions without an explicit code, add them to `moran.words.dict.yaml` at the end of the first block after the YAML header.
