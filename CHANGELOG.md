# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## v1.2.1 - 2026-05-21
#### Bug Fixes
- (**ui**) collapse results table height to match content - (e9f3ead) - Prokhor
- (**ui**) make approximation table formula column elastic - (9406540) - Prokhor

- - -

## v1.2.0 - 2026-05-21
#### Features
- (**backend**) add approximation module - (e04a3c3) - Prokhor
- (**calc**) add least squares approximator - (dcefe4c) - Prokhor
- (**gauss**) add Gaussian elimination via calc library and backend module - (732b913) - Prokhor
- (**ui**) add noise level slider to approximation generator - (b5cfc1f) - Prokhor
- (**ui**) clamp generated approximation data to x>0 and y>0 - (ba26e35) - Prokhor
- (**ui**) randomise approximation tab data across seven archetypes - (50f6d54) - Prokhor
- (**ui**) draw x=0 and y=0 axis lines on approximation chart - (5371213) - Prokhor
- (**ui**) replace approximation row swatches with toggle buttons - (2318395) - Prokhor
- (**ui**) add approximation tab - (31445af) - Prokhor
- (**ui**) add Gauss method as first navigation tab - (860f7f9) - Prokhor
- (**ui**) add app icon (integral symbol on green rounded square) - (d86e31a) - Prokhor
#### Bug Fixes
- (**ui**) make every archetype reproduce its target model at 0% noise - (e19449b) - Prokhor
- (**ui**) equalize solution/residuals block heights in Gauss tab - (9df6867) - Prokhor
- (**ui**) apply Qt QML review findings (style import, sourceSize, redundant anchor) - (6b5bf6a) - Prokhor
- (**ui**) use MyTextField for readable text and placeholder colors - (c06572a) - Prokhor
#### Revert
- (**ui**) drop sourceSize on equation icon Image - (0cb7bed) - Prokhor
#### Documentation
- (**reports**) replace lab4 screenshot placeholder with real capture - (4eb0b49) - Prokhor
- (**reports**) add lab4 report - (8ae4cd4) - Prokhor
- (**reports**) add lab4 flowcharts - (aa80cc1) - Prokhor
- (**reports**) replace screenshot placeholders with real app captures - (8c00da6) - Prokhor
- (**reports**) reserve app screenshot slot in each lab report - (8adec70) - Prokhor
- (**reports**) add lab1 report and embed source code in lab2/lab3 - (142d85c) - Prokhor
#### Refactoring
- (**backend**) move backend modules into backend/ directory - (d82bb13) - Prokhor
- (**ui**) rework Gauss tab layout to match the other modules - (84fd063) - Prokhor
#### Miscellaneous Chores
- (**descriptions**) add lab4 PDFs (task + lecture) - (1a7f963) - Prokhor
- (**descriptions**) rename description/ to descriptions/ and add lab1 task - (8e37e54) - Prokhor
- (**reports**) finalize doc/ to reports/ rename for shared resources - (94bb50a) - Prokhor
- strip descriptive comments from lab4 sources - (0fd7940) - Prokhor

- - -

## v1.1.0 - 2026-05-07
#### Features
- (**calc**) integration methods with Runge refinement and improper-integral handling - (bf2e9c4) - Prokhor
- (**ui**) unified math typesetting for cards and active accent bar in nav buttons - (57b0c58) - Prokhor
- (**ui**) integration module with function picker and per-method results table - (5e7aae9) - Prokhor
- linear interpolation for systems - (14fd77a) - Prokhor
#### Bug Fixes
- (**report**) shrink large flowcharts so they fit on a single page - (3d02ad2) - Prokhor
- (**ui**) header title to Вычислительная математика - (6342cc7) - Prokhor
- (**ui**) resultStatus is a QString from the backend, not an int - (88a233b) - Prokhor
#### Revert
- (**report**) restore order-of-accuracy notes after confirming they're in the lecture - (b57f39a) - Prokhor
#### Documentation
- (**flowcharts**) expand try_principal_value tail handling into explicit decision branches - (63a2f82) - Prokhor
- (**flowcharts**) drop unreachable d>0 guard from try_principal_value flowchart - (3652927) - Prokhor
- (**flowcharts**) drop unreachable lo<hi guard from limit_at_endpoint flowchart - (7b13912) - Prokhor
- (**flowcharts**) align flowcharts with refactored code and add procedure-level diagrams for improper handling - (da05201) - Prokhor
- (**flowcharts**) add lab3 flowcharts for integrators, Runge loop, and improper handling - (9a86411) - Prokhor
- (**flowcharts**) align diagrams with solver code - (2784208) - Prokhor
- (**report**) rewrite lab3 in lab2 style and trim explanations - (c367531) - Prokhor
- (**report**) add lab3 typst report with variant-5 computational part - (bea19dc) - Prokhor
#### Refactoring
- (**backend**) split Backend.hpp into per-module classes (Root, System, Integration) - (b689c44) - Prokhor
- (**calc**) convert integrators to OOP class hierarchy with virtual apply() - (d1fcc45) - Prokhor
#### Miscellaneous Chores
- (**calc**) drop isFinite paranoia in prepareIntervals - (cfb6207) - Prokhor
- (**repo**) configure cog with v-prefixed tags - (b2f2f7b) - Prokhor
- (**repo**) move task PDFs and lectures into description folder - (92066b9) - Prokhor
- (**report**) remove unused lab3 screenshot placeholders from doc/resources - (a255e8b) - Prokhor
#### Style
- drop stale comments and dead code across calc and components - (c5f1256) - Prokhor

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).