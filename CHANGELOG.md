# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

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