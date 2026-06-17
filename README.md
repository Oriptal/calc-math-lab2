# comp-math

Десктоп-приложение для лабораторных работ курса вычислительной математики ИТМО: шесть вкладок в одном Qt-приложении — метод Гаусса (ЛР №1), уточнение корня уравнения и решение системы (ЛР №2), численное интегрирование (ЛР №3), аппроксимация табличной функции МНК (ЛР №4), интерполяция функции (ЛР №5) и решение ОДУ — задача Коши (ЛР №6). Математика чисто на C++, UI — QML.

> 📦 **Установка готовых сборок** (Linux x86_64/ARM64 + macOS universal) — см. **[INSTALL.md](INSTALL.md)** (там же — как обойти Gatekeeper на macOS).

## Что реализовано

- **ЛР №1**: метод Гаусса с выбором главного элемента, определитель, невязки, три случая (единственное / нет / бесконечно).
- **ЛР №2**: половинное деление, метод Ньютона, простые итерации; валидация интервала; двумерная система через метод простых итераций с трассировкой нулевых кривых.
- **ЛР №3**: 5 квадратурных формул (левые/правые/средние прямоугольники, трапеции, Симпсон), правило Рунге, обработка несобственных интегралов 2-го рода, главное значение Коши.
- **ЛР №4**: 6 моделей МНК (линейная, полиномиальные 2-й и 3-й степени, экспоненциальная, логарифмическая, степенная), коэффициент детерминации $R^2$ с пороговыми сообщениями, коэффициент корреляции Пирсона для линейной, выбор лучшей модели по δ, общий график.
- **ЛР №5**: интерполяция табличной функции — многочлены Лагранжа, Ньютона (1-я/2-я формулы на конечных разностях) и Гаусса (вперёд/назад), а также схемы Стирлинга и Бесселя; таблица конечных разностей, проверка равноотстоящих узлов и автоматический выбор формулы по положению точки; значения в двух промежуточных точках $X_1$, $X_2$.
- **ЛР №6**: задача Коши для ОДУ 1-го порядка — усовершенствованный метод Эйлера ($p=2$), метод Рунге–Кутта 4-го порядка ($p=4$) и многошаговый предиктор-корректор Милна; оценка погрешности по правилу Рунге (одношаговые методы) и по точному решению (Милн), автоматический подбор шага дроблением пополам; набор уравнений с известными точными решениями, общий график решений.

Подробнее по архитектуре и алгоритмам — [Wiki](https://git.oriptal.dev/cadmin/calc-math-lab2/wiki).

## Стек

- C++17
- Qt 6.8: Quick, Quick Controls Basic, Charts, Widgets, Concurrent
- CMake ≥ 3.16
- Typst — отчёты в `reports/`
- Graphviz (`dot`) — блок-схемы и UML-диаграммы

## Структура

| Каталог | Содержимое |
|---|---|
| `calc/` | Чистая C++-математика: `Gauss`, `Solvers`, `Integrators`, `Approximation`, `Interpolation`, `Ode` (без Qt-зависимостей) |
| `backend/` | `Q_INVOKABLE`-фасад `Backend` и модули-обёртки для каждой ЛР |
| `components/` | QML-модули и общие компоненты (`MyButton`, `MyTextField`, `EquationCard`…) |
| `assets/` | SVG-карточки уравнений/систем/интегрантов/функций/ОДУ + иконка приложения |
| `reports/` | Typst-отчёты `lab1.typ` … `lab6.typ` + блок-схемы (`.dot`/`.png`/`.svg`) |
| `descriptions/` | PDF-задания и лекции |

## Локальная сборка

```bash
cmake -S . -B build
cmake --build build
./build/comp-math
```

Зависимости (Arch): `qt6-base qt6-declarative qt6-charts qt6-tools`.
Debian/Ubuntu: `qt6-base-dev qt6-declarative-dev qt6-charts-dev`.

## Релизный билд с упаковкой

```bash
./package.sh
```

Скрипт делает Release-сборку и Qt deploy в `dist/`. Готовую папку можно копировать на любую Linux-машину без установленной Qt — рантайм едет в `dist/lib/` и `dist/plugins/`.

Кастомизация через env-переменные:

- `BUILD_DIR` — куда собирать (по умолчанию `build-release`)
- `DIST_DIR` — куда устанавливать (по умолчанию `dist`)
- `BUILD_TYPE` — `Release` или `Debug`
- `EXTRA_CMAKE_ARGS` — дополнительные флаги CMake (в CI так собирается universal-бинарник macOS: `-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64`)

## Отчёты

```bash
typst compile --root . reports/lab1.typ reports/lab1.pdf
typst compile --root . reports/lab2.typ reports/lab2.pdf
typst compile --root . reports/lab3.typ reports/lab3.pdf
typst compile --root . reports/lab4.typ reports/lab4.pdf
typst compile --root . reports/lab5.typ reports/lab5.pdf
typst compile --root . reports/lab6.typ reports/lab6.pdf
```

Флаг `--root .` нужен, чтобы `#raw(read("../calc/..."))` мог подтянуть исходники.

## Релизы

Версионирование — через cocogitto: `cog bump --auto` (или `--major` / `--minor` / `--patch` явно) создаёт коммит и тег `vX.Y.Z`.

Сборка — GitHub Actions (репозиторий зеркалится с Forgejo на GitHub ради бесплатных раннеров). По пушу тега `v*` workflow `.github/workflows/release.yml` матрицей собирает три цели (macOS — один universal-бинарник на обе архитектуры):

| Платформа | Раннер | Артефакт |
|---|---|---|
| Linux x86_64 | `ubuntu-22.04` | `calc-math-lab2-linux-x86_64.tar.gz` |
| Linux ARM64 | `ubuntu-24.04-arm` | `calc-math-lab2-linux-arm64.tar.gz` |
| macOS (Intel + Apple Silicon) | `macos-14` | `calc-math-lab2-macos-universal.dmg` |

Готовые ассеты публикуются обратно в [Forgejo-релиз](https://git.oriptal.dev/cadmin/calc-math-lab2/releases) через API.

> macOS-бандл не подписан Apple-сертификатом: при первом запуске — ПКМ → «Открыть», либо снимите карантин: `xattr -dr com.apple.quarantine /Applications/comp-math.app`.

## Ссылки

- **Wiki**: <https://git.oriptal.dev/cadmin/calc-math-lab2/wiki>
- **Релизы**: <https://git.oriptal.dev/cadmin/calc-math-lab2/releases>
