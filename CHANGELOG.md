# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## [1.0.1](https://github.com/sravioli/warp.wz/compare/48d868834d323ebaf3419a9aaebdf2c16d04ba2c..1.0.1) - 2026-11-22
#### Style
- (**ribbon**) stop shadowing the logger parameter with the log module - ([48d8688](https://github.com/sravioli/warp.wz/commit/48d868834d323ebaf3419a9aaebdf2c16d04ba2c)) - sravioli

- - -

## [1.0.0](https://github.com/sravioli/warp.wz/compare/769bb50e39497954d976fabcf4eabf35fb540f87..1.0.0) - 2026-11-22
#### Features
- (**filesystem**) add state_dir, data_dir and atomic write_file - ([52a307a](https://github.com/sravioli/warp.wz/commit/52a307aa46bbcaebadde78720c78519c1c6006c1)) - sravioli
- absorb log.wz and ribbon.wz, load modules lazily, validate config - ([93b62c3](https://github.com/sravioli/warp.wz/commit/93b62c36853b7944405a11770a3042f2ab726463)) - sravioli
#### Bug Fixes
- (**list**) keep every nil-key item in unique, share tilde helpers - ([eed9c90](https://github.com/sravioli/warp.wz/commit/eed9c90ecf3f976e6d7f3ce33e2d9c8c04cc7c02)) - sravioli
- (**maths**) return integers from round and round_to - ([f4926a9](https://github.com/sravioli/warp.wz/commit/f4926a9c08d15f24d07e82ad50c055ba6e6c462e)) - sravioli
- (**path**) keep the parts after an empty segment in shorten - ([1974faf](https://github.com/sravioli/warp.wz/commit/1974faf41a1e6e1d64139f99489ea0edcd9b2ca0)) - sravioli
#### Documentation
- add minit.lua for reproducing bugs - ([7053556](https://github.com/sravioli/warp.wz/commit/70535564288efc33fb8aea02bbe7a8768c736622)) - sravioli
#### Continuous Integration
- pass the release tag to the shell through env - ([067060a](https://github.com/sravioli/warp.wz/commit/067060a35138595ec5fc40464eb132a717100f09)) - sravioli
- release from the pushed tag - ([d68323a](https://github.com/sravioli/warp.wz/commit/d68323a4272734dced00c4bdfba4e2e5239d485e)) - sravioli
- count only the plugin's own files in coverage - ([37c928b](https://github.com/sravioli/warp.wz/commit/37c928ba412887a0653bd033b5bd826a398131a2)) - sravioli
- bump cocogitto/cocogitto-action from 3.11 to 4 in the actions group across 1 directory (#5) - ([d1b40e4](https://github.com/sravioli/warp.wz/commit/d1b40e405cf4194bfb6f06eb644309125a0cb8b6)) - [@sravioli](https://github.com/sravioli)
- adapt workflows to cocogitto-action v4 - ([14132d9](https://github.com/sravioli/warp.wz/commit/14132d91e798cf0fa11b4009d0e2076677dc600f)) - sravioli
- bump cocogitto/cocogitto-action - ([769bb50](https://github.com/sravioli/warp.wz/commit/769bb50e39497954d976fabcf4eabf35fb540f87)) - dependabot[bot]

- - -

## [0.2.1](https://github.com/sravioli/warp.wz/compare/296ee31207deb119a808cd090777b8309d61cc46..0.2.1) - 2026-11-16
#### Bug Fixes
- (**string**) strip charset designations in strip_ansi - ([d568df0](https://github.com/sravioli/warp.wz/commit/d568df0f459793b8c19e6f2cc5b74b26fc667ab1)) - sravioli
#### Documentation
- (**contributing**) document the signed-commit requirement - ([54b83e9](https://github.com/sravioli/warp.wz/commit/54b83e9592fe92b580f36303ce07f94063fd45ce)) - sravioli
- (**contributing**) unify guides and templates - ([296ee31](https://github.com/sravioli/warp.wz/commit/296ee31207deb119a808cd090777b8309d61cc46)) - sravioli
- (**readme**) unify badge style and add release badge - ([c4dda3a](https://github.com/sravioli/warp.wz/commit/c4dda3a21995cb4a146d416af19291c7e029a095)) - sravioli
- (**readme**) align checks section - ([1407ff1](https://github.com/sravioli/warp.wz/commit/1407ff18d2994e08f8a00e46da2b80208f7936cd)) - sravioli
- document working-tree local checkout setup - ([9ec9fae](https://github.com/sravioli/warp.wz/commit/9ec9faecd5fb194806daec3739858fabaf644c25)) - sravioli
#### Continuous Integration
- build the API reference from a majority of three LuaLS runs - ([562849d](https://github.com/sravioli/warp.wz/commit/562849dc7b3e0b6c4db7fcf30448f4839b2f2d1c)) - sravioli
- update the actions to the versions Dependabot proposed - ([0c150c2](https://github.com/sravioli/warp.wz/commit/0c150c24becfb6ed203bc45bd1925866220c09c3)) - sravioli
- pin StyLua to 2.6.0 - ([bfe8013](https://github.com/sravioli/warp.wz/commit/bfe80133a307bc48c3a317f9fa92743afeabecd2)) - sravioli
- fix the flaky API check and the EditorConfig rate limit - ([05199a3](https://github.com/sravioli/warp.wz/commit/05199a3c433326f04b06a79c1bad77cb93cf428d)) - sravioli

- - -

## [0.2.0](https://github.com/sravioli/warp.wz/compare/7697396d2f2ace257925023cc6e026768d5e9edd..0.2.0) - 2026-11-15
#### Features
- (**filesystem**) add mkdir and is_dir fallback - ([7c5f20a](https://github.com/sravioli/warp.wz/commit/7c5f20ac8f8d64a4c646afaccb08a27e0d8857ff)) - sravioli
- (**path**) add tilde and windows-aware normalize - ([6927340](https://github.com/sravioli/warp.wz/commit/69273400b567095fd1bb66cb925f8d129e00c82d)) - sravioli
- (**process**) add process module - ([055d5d5](https://github.com/sravioli/warp.wz/commit/055d5d55872d92ce2f21192362628acb97c4dc74)) - sravioli
#### Bug Fixes
- (**filesystem**) match home prefix, find worktrees - ([e99709f](https://github.com/sravioli/warp.wz/commit/e99709fdf92d3b3a61f3638f28457bd7d6fb61cc)) - sravioli
#### Performance Improvements
- (**bootstrap**) keep plugin list across reloads - ([e49ac4d](https://github.com/sravioli/warp.wz/commit/e49ac4ddd1918fdcfdd4bf76714e54aada59d93d)) - sravioli
- (**bootstrap**) share plugin discovery snapshot - ([7697396](https://github.com/sravioli/warp.wz/commit/7697396d2f2ace257925023cc6e026768d5e9edd)) - sravioli
- (**string**) use native truncation - ([d08ff16](https://github.com/sravioli/warp.wz/commit/d08ff1667faf144c4715bbc729df42395c2e8e04)) - sravioli
#### Documentation
- (**readme**) update plugin READMEs - ([84c8888](https://github.com/sravioli/warp.wz/commit/84c8888c52b228aff09dd21a6695aa686ec6512c)) - sravioli
#### Tests
- (**filesystem**) cover home prefix and worktrees - ([00b00b5](https://github.com/sravioli/warp.wz/commit/00b00b5e61a474a4dbf997dfdb5272aec5a6f0b5)) - sravioli
- (**mocks**) add truncate_left - ([a2b9403](https://github.com/sravioli/warp.wz/commit/a2b9403636746613546fd27c095f71a6ef968304)) - sravioli

- - -

## [0.1.3](https://github.com/sravioli/warp.wz/compare/fa5a1988f289ec5e6684f7ad0dc649040174229a..0.1.3) - 2026-05-14
#### Documentation
- (**github**) add pull request templates - ([0f987f7](https://github.com/sravioli/warp.wz/commit/0f987f78ee8eb05dc4ad1f414b0a38845e5f8057)) - sravioli
- (**github**) polish issue templates - ([118d64e](https://github.com/sravioli/warp.wz/commit/118d64efa1af87e4e0f6fb3236ed8ec39304c9e6)) - sravioli
- (**lua**) polish comment wording - ([65d23a4](https://github.com/sravioli/warp.wz/commit/65d23a4a6c3a2620e2152870875f8af3def3aff4)) - sravioli
- (**lua**) polish comment wording - ([d948aa9](https://github.com/sravioli/warp.wz/commit/d948aa9a3640ec7efe24066a2ba046211a674810)) - sravioli
- (**readme**) improve readme consistency - ([562aa25](https://github.com/sravioli/warp.wz/commit/562aa258e010ce46a654a1de3de35bdf7faeeffb)) - sravioli
- (**readme**) improve readme clarity - ([fa5a198](https://github.com/sravioli/warp.wz/commit/fa5a1988f289ec5e6684f7ad0dc649040174229a)) - sravioli

- - -

## [0.1.2](https://github.com/sravioli/warp.wz/compare/8a052c2fa08c83997a828dde20f39f2c357dc236..0.1.2) - 2026-04-10
#### Bug Fixes
- (**filasystem**) strip leading `/` on windows - ([8a052c2](https://github.com/sravioli/warp.wz/commit/8a052c2fa08c83997a828dde20f39f2c357dc236)) - sravioli
#### Documentation
- add type annotations section to readme - ([2bafc2d](https://github.com/sravioli/warp.wz/commit/2bafc2dbd3d3641303406bb9fa6aa27f3b922fb4)) - sravioli

- - -

## [0.1.1](https://github.com/sravioli/warp.wz/compare/4a098f3415ca05150c8d8383f3036770f51a4155..0.1.1) - 2026-03-31
#### Features
- add extend_unique function and merge functionality with tests - ([4a098f3](https://github.com/sravioli/warp.wz/commit/4a098f3415ca05150c8d8383f3036770f51a4155)) - sravioli
#### Documentation
- update readme and improve path module documentation - ([bfbd350](https://github.com/sravioli/warp.wz/commit/bfbd350a56449c7d01c12cbf8919c25393a2cad0)) - sravioli
- update readme - ([3977c1e](https://github.com/sravioli/warp.wz/commit/3977c1e0a725145b52eb55716f1748b099711cf2)) - sravioli

- - -

## [0.1.0](https://github.com/sravioli/warp.wz/compare/94ac089b09d153ce4ce01ae2f719c9dd65638b65..0.1.0) - 2026-03-30
#### Features
- (**api**) expose missing modules in api - ([94d3b2a](https://github.com/sravioli/warp.wz/commit/94d3b2ac3e0d56ac8ca22e74a224cbe95251d594)) - sravioli
- (**api**) expose maths and tbl modules - ([b6d77e0](https://github.com/sravioli/warp.wz/commit/b6d77e05794da3c5fffb1c05a6d7bcd9a021444c)) - sravioli
- (**filesystem**) add filesystem module - ([6927144](https://github.com/sravioli/warp.wz/commit/692714460b2d9c8b8d13ec8f26b94b9849cf798a)) - sravioli
- (**path**) add path module - ([d61b800](https://github.com/sravioli/warp.wz/commit/d61b8009a317fdea2772885746120beb4ed423fc)) - sravioli
- (**string**) add string module - ([98361a8](https://github.com/sravioli/warp.wz/commit/98361a8dce1d0a207d93b790404f6083d0f0fb29)) - sravioli
- (**tbl**) add reverse, isempty, isblank functions - ([f8fdc80](https://github.com/sravioli/warp.wz/commit/f8fdc8045cdc05ebfde27f3df44e3c1240a75df8)) - sravioli
- add new api - ([cf0bdba](https://github.com/sravioli/warp.wz/commit/cf0bdba4db646b6885feb90bcccf4500ee47ef63)) - sravioli
- add benchmarks - ([976b009](https://github.com/sravioli/warp.wz/commit/976b009faedc1a6578602fae2c66737d914dfc49)) - sravioli
- separate concerns between list and table - ([2b60869](https://github.com/sravioli/warp.wz/commit/2b60869c417fd7f3c9fa34930cf17ea0cce673f9)) - sravioli
- add table utilities - ([abdee63](https://github.com/sravioli/warp.wz/commit/abdee631f81eb388aec9d1f690c3be025ca50813)) - sravioli
- add maths utilities - ([c1b0141](https://github.com/sravioli/warp.wz/commit/c1b0141615252fac85bef6d4f22c02fe2b491972)) - sravioli
#### Bug Fixes
- (**cocogitto**) remove boilerplate comments - ([18d0727](https://github.com/sravioli/warp.wz/commit/18d0727b73b6ef18bff92c1d1b1c4a54494319e6)) - sravioli
- (**mock**) improve io.open mock to match real contract and prevent CI crashes - ([70c2cca](https://github.com/sravioli/warp.wz/commit/70c2cca5551db06701bcf69f036898a30633ec7d)) - sravioli
- (**string**) validate truncation mode - ([a429984](https://github.com/sravioli/warp.wz/commit/a4299843a27e6729d26d60fc0cc6f799fd64e7c7)) - sravioli
- (**string**) respect padding valued - ([3afb2da](https://github.com/sravioli/warp.wz/commit/3afb2da2295327ddc52d875faaf2c99ea85137ea)) - sravioli
- ![BREAKING](https://img.shields.io/badge/BREAKING-red) (**table**) rename `tbl` to `table` - ([6d70be5](https://github.com/sravioli/warp.wz/commit/6d70be596c3db6dceb1aa7d629fbb4500ae03e30)) - sravioli
- rename `.stylua.toml` to `stylua.toml` - ([054b9dc](https://github.com/sravioli/warp.wz/commit/054b9dc50e8362e4c7f04390edb9d98fdb7b720f)) - sravioli
- rm caching - ([40d78c0](https://github.com/sravioli/warp.wz/commit/40d78c0eeeca49704adec9e872fec10e6ccb0969)) - sravioli
- rm deps from `sravioli/memo.wz` - ([5832ede](https://github.com/sravioli/warp.wz/commit/5832edefac6fc8fa4a3648e67b7684eada4e093b)) - sravioli
#### Performance Improvements
- improve fs, path and string performance - ([e34c6de](https://github.com/sravioli/warp.wz/commit/e34c6de0a2f0dd6bd6aec4129962f19ea59e6446)) - sravioli
- improve table performance - ([43760ab](https://github.com/sravioli/warp.wz/commit/43760aba25a6d619fb9d986355be1609ee234a2a)) - sravioli
- improve string module performance - ([4003aeb](https://github.com/sravioli/warp.wz/commit/4003aeb857940b8bdc252e2480e2984380407a63)) - sravioli
- improve list module performance - ([8781e5e](https://github.com/sravioli/warp.wz/commit/8781e5e8692f8081db67f162b7e0dc36395c58b6)) - sravioli
- improve filessytem module performance - ([adb5b5c](https://github.com/sravioli/warp.wz/commit/adb5b5c5502c31626a2ad2139e6cb7f76c30a88a)) - sravioli
- improve path module performance - ([dfdfbc7](https://github.com/sravioli/warp.wz/commit/dfdfbc745e52732b5763cb541efceb5f606bc174)) - sravioli
- improve cartesian performances - ([80f02b4](https://github.com/sravioli/warp.wz/commit/80f02b4f1e6d13c5a17e9605a552b04364c24ab6)) - sravioli
#### Documentation
- (**maths**) update code documentation - ([445dd79](https://github.com/sravioli/warp.wz/commit/445dd797aff87fd811c67f7e1dac655754e2731b)) - sravioli
- update LuaCATS annotations - ([04aab79](https://github.com/sravioli/warp.wz/commit/04aab794e5a3c6c82f381fa16a19d3bf5ddc23b7)) - sravioli
- update readme - ([133febe](https://github.com/sravioli/warp.wz/commit/133febe16c42f5c224848d07b7014b9e94f23d71)) - sravioli
- add documentation - ([b0756d0](https://github.com/sravioli/warp.wz/commit/b0756d0ab128dea5f169550c5ef5c87ec2dd4f5d)) - sravioli
- add code type annotations - ([292d695](https://github.com/sravioli/warp.wz/commit/292d69540b8149b562a731e560aa97184ddb7c0c)) - sravioli
- add code comments - ([8332fde](https://github.com/sravioli/warp.wz/commit/8332fde9fd52baad5bbeb84288b0f42125ce0124)) - sravioli
#### Tests
- add integration tests - ([5a5a331](https://github.com/sravioli/warp.wz/commit/5a5a33193b19bcb63b9fd722bc666c7ca1f786fb)) - sravioli
- merge redundant tests, remove useless ones - ([13ffddf](https://github.com/sravioli/warp.wz/commit/13ffddfc9b94b70a59314a17533953cbf4af5ba0)) - sravioli
- add edge case tests - ([e842a9c](https://github.com/sravioli/warp.wz/commit/e842a9c0cf86c2a2ee4b5fb53b99445ebe3c875e)) - sravioli
- add path module tests - ([a60ba8c](https://github.com/sravioli/warp.wz/commit/a60ba8c9520bfa813c198f9765061f627d1e4fb8)) - sravioli
- add unit tests - ([0fd5a0f](https://github.com/sravioli/warp.wz/commit/0fd5a0f31e5435401cd48d8e0bc74321eb34922b)) - sravioli
#### Continuous Integration
- add lint, release and test jobs - ([4a98d19](https://github.com/sravioli/warp.wz/commit/4a98d19c0b39408f74b693fd1af950ff3715f5f3)) - sravioli
#### Style
- format with stylua - ([a9afa22](https://github.com/sravioli/warp.wz/commit/a9afa229f68c2de6b02c11e59da28e8936c4d606)) - sravioli
- format with stylua - ([be3efce](https://github.com/sravioli/warp.wz/commit/be3efce67d5a1ac00e90564206a830e4473aeda3)) - sravioli
- format with stylua - ([0c1e908](https://github.com/sravioli/warp.wz/commit/0c1e90830a5c818d4eff7de3d1aec159562cd402)) - sravioli
- format with stylua - ([1e658ea](https://github.com/sravioli/warp.wz/commit/1e658ea0c018872b1f318dffaff7fb495129c244)) - sravioli
- format with stylua - ([3dc05f7](https://github.com/sravioli/warp.wz/commit/3dc05f7e475f8903de7ca59933533fe406390999)) - sravioli
- formatting - ([698eb34](https://github.com/sravioli/warp.wz/commit/698eb34179328ef9ec36279c7be0bf3eb280bcc3)) - sravioli

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).