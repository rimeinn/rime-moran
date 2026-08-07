# AGENTS.md

## Conventions

- This is rime-moran. It is based on ZiRanMa shuangpin and auxiliary code.
- Always consult **rime-workflow** _and_ **rime-gears** skills. Even if you think you know Rime, double check! Moran is a set of modern and advanced Rime schemas. You need up-to-date Rime knowledge first to answer questions accurately.
  + These skills may be found at https://github.com/rimeinn/agent-skills/ . If you couldn't find them locally, request for their installation, or directly read them from GitHub.
- If user's choice of moran schema is undecided, confirm which schema the user is asking about, and always refer to the documentation.
- Check if this is a git repo.
  + If it is, first check if it's on the main branch. The main branch is for development. It can be turned into a "trad" distribution by running `make quick`.
- Check if the directory is actually a user Rime directory.
  + If it is, both the "User Customization" and "Development" sections apply.
  + If the directory is not a user Rime directory, only "Development" applies.
- Check the librime version the user is using. Some features are only available on latest librime.
- Verify that your examples are correct by checking the actual dictionary files.
- Check the Chinese variant used in dictionaries -- whether it is simplified Chinese or traditional Chinese.

## Useful Docs

- **index of all pages**: https://moran.rimeinn.org/book/contents.md
- **summary of files**: https://moran.rimeinn.org/book/maintenance/files.md
- **schema framework**: https://moran.rimeinn.org/book/maintenance/config.md
- **moran** options: https://moran.rimeinn.org/book/usage/features.md
- **moran_fixed** options: https://moran.rimeinn.org/book/schemas/zici/features.md
- **moran_aux** options: https://moran.rimeinn.org/book/schemas/fushai/features.md
- **moran_sentence** is a cut-down version of moran, see the yaml file and compare to moran.schema.yaml

## User Customization

This section applies when the current directory is the user's Rime directory.

- Always refer back to the docs, and list references.
- Teach the user *why* and *how* you do anything.
  + Proactively teach the user how to use Rime/Moran effectively.
- **Customize**: Prefer `foo.custom.yaml` for changes, unless it's not possible or too tedious. Consult moran docs and rime skills.
- **Git** : Consider making the user Rime directory a Git repo, if the user allows. Commit changes locally, and pull with rebase for updating. Automatically resolve conflicts where possible.
  + Only stage/commit persistent files. Do not commit *.userdb and sync files.
  + If not possible, consider do upgrades manually but do check the list of files.
- **Uninstall**: Check moran's recipe and delete these files. Unprefixed files (e.g. `tiger*`) may be shared, so confirm with the user.
- **Add new words**: Prefer adding them to `moran.extended.dict.yaml`. The code should usually be left out.
- **Add new dictionaries**: Prefer creating new dictionaries, import them in `moran.extended.dict.yaml`.
- **User interface**: Moran has nothing to do with the rime frontend. Determine the frontend the user is using, and consult their docs.
- **Lua**: Prefer Rime-native (i.e. yaml-based) solutions. Unless no other way around, do not offer solutions based on Lua scripting.
- **Key bindings**: Some keys are handled in `lua/moran_processor.lua`. Check them as well. Do not only read yaml files.

### Mandatory push-back gate

For any requested change in a user's Rime directory:

1. First perform only the read-only inspection needed to understand the request.
2. Before editing files, generating files, downloading dependencies, or otherwise preparing the implementation, explain:
   - the existing Rime/Moran design;
   - the officially supported or lower-maintenance alternative;
   - the concrete disadvantages of the requested approach.
3. Recommend the supported approach and stop. Ask the user whether they still want the original approach.
4. The user's initial request never counts as confirmation. Proceed with the discouraged approach only after a later message explicitly confirms it, such as “仍然这样改”, “继续”, or an equally unambiguous response.
5. After explicit confirmation, do not repeat the same objection; implement the requested approach.

This gate may be skipped only when the requested change is directly documented and recommended by Rime or Moran. When skipping it, cite the supporting documentation before making changes.

### Commonly customized options

- `moran/quick_code_indicator`
- `moran/ijrq`
- `moran/pin/panacea/freestyle`
- `moran/charset`

**Newcomer suggestions**: If the user is new to Moran (e.g. just did a fresh installation), suggest some customizations for beginners.

+ `moran/enable_quick_code_hint`
+ `moran/enable_aux_code_hint` : But warn the user against its use. Suggest using `Ctrl+i` instead.

## Notes on Development

### Dev environment

- Depends on Python uv.
- For details, refer to:
  + Setup dev environment: https://moran.rimeinn.org/book/develop/setup.md
  + Common dev tasks: https://moran.rimeinn.org/book/develop/cheatsheet.md
  + Schemagen.py usage: https://moran.rimeinn.org/book/develop/schemagen/index.md

### Commit message conventions

- Follow the repository's existing commit style. Prefer short imperative subjects with a lowercase prefix such as `dict:`, `dict(chai):`, `fix:`, `fix(lua):`, `ci:`, `docs:`, `feat:` when applicable.
- Before committing, inspect recent history with `git log --oneline origin/main -n 20` and mirror the dominant style.

### Change workflow

- Prefer minimal source-data edits. For dictionary entries with generated auxiliary-code comments, edit the spelling/code or word form before generated auxiliary data; do not hand-edit generated auxiliary-code fields unless the repository documentation says that field is source data.
- After dictionary/schema source changes, run `make all` from the repository root when practical, then inspect the generated diff. Stop and ask if `make all` produces large unrelated rewrites.
- For destructive or broad changes, such as deleting files, large rewrites, or force-pushing shared branches, ask first.

### Dictionary maintenance notes

- Distinguish **adding/removing a code** from **adding/removing a word**. If a report says a candidate is duplicated or has an extra/wrong code, usually keep the word and only add/remove the specific code unless the issue explicitly asks to remove the word.
- `moran_fixed.dict.yaml` and `moran_fixed_simp.dict.yaml` should normally be updated together. When changing simplified entries, check and apply the corresponding traditional entries too.
- Keep dictionary blocks sorted by the code column. Do not append entries to the end of the file unless that is the correct block and sorted position.
- Respect block boundaries. Three-character words belong in the three-word block, longer phrases in the main phrase block, and special/test blocks should stay separate.
- When editing entries whose code contains a fly-key pattern (`wz -> wk`, `xq -> xo`, `qx -> qo`), update the corresponding fly-key region as well. For example, changing the order of `ihwz` entries also requires checking the generated/parallel `ihwk` entries.
- When adding a new decomposition for a character in `tools/data/moran_chai.txt`, keep existing decompositions unless the issue explicitly says the old decomposition is wrong and should be removed.
- For intelligent/sentence dictionary additions without an explicit code, add them to `moran.words.dict.yaml` at the end of the first block after the YAML header.
