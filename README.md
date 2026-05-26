# comp-math

Десктоп-приложение для лабораторных работ курса вычислительной математики ИТМО: четыре вкладки в одном Qt-приложении — метод Гаусса (ЛР №1), уточнение корня уравнения и решение системы (ЛР №2), численное интегрирование (ЛР №3) и аппроксимация табличной функции МНК (ЛР №4). Математика чисто на C++, UI — QML.

## Что реализовано

- **ЛР №1**: метод Гаусса с выбором главного элемента, определитель, невязки, три случая (единственное / нет / бесконечно).
- **ЛР №2**: половинное деление, метод Ньютона, простые итерации; валидация интервала; двумерная система через метод простых итераций с трассировкой нулевых кривых.
- **ЛР №3**: 5 квадратурных формул (левые/правые/средние прямоугольники, трапеции, Симпсон), правило Рунге, обработка несобственных интегралов 2-го рода, главное значение Коши.
- **ЛР №4**: 6 моделей МНК (линейная, полиномиальные 2-й и 3-й степени, экспоненциальная, логарифмическая, степенная), коэффициент детерминации $R^2$ с пороговыми сообщениями, коэффициент корреляции Пирсона для линейной, выбор лучшей модели по δ, общий график.

Подробнее по архитектуре и алгоритмам — [Wiki](https://git.oriptal.dev/cadmin/calc-math-lab2/wiki).

## Стек

- C++20
- Qt 6.8: Quick, Quick Controls Basic, Charts, Widgets, Concurrent
- CMake ≥ 3.16
- Typst — отчёты в `reports/`
- Graphviz (`dot`) — блок-схемы и UML-диаграммы

## Структура

| Каталог | Содержимое |
|---|---|
| `calc/` | Чистая C++-математика: `Gauss`, `Solvers`, `Integrators`, `Approximation` (без Qt-зависимостей) |
| `backend/` | `Q_INVOKABLE`-фасад `Backend` и модули-обёртки для каждой ЛР |
| `components/` | QML-модули и общие компоненты (`MyButton`, `MyTextField`, `EquationCard`…) |
| `assets/` | SVG-карточки уравнений/систем/интегрантов + иконка приложения |
| `reports/` | Typst-отчёты `lab1.typ` … `lab4.typ` + блок-схемы (`.dot`/`.png`/`.svg`) |
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

## Отчёты

```bash
typst compile --root . reports/lab1.typ reports/lab1.pdf
typst compile --root . reports/lab2.typ reports/lab2.pdf
typst compile --root . reports/lab3.typ reports/lab3.pdf
typst compile --root . reports/lab4.typ reports/lab4.pdf
```

Флаг `--root .` нужен, чтобы `#raw(read("../calc/..."))` мог подтянуть исходники.

## Релизы

Через cocogitto + Forgejo Actions. Бамп версии: `cog bump --auto` (или `--major` / `--minor` / `--patch` явно), затем `git push --tags`. Workflow `.forgejo/workflows/release.yml` собирает релизный архив и публикует его как Forgejo-релиз.

## Ссылки

- **Wiki**: <https://git.oriptal.dev/cadmin/calc-math-lab2/wiki>
- **Релизы**: <https://git.oriptal.dev/cadmin/calc-math-lab2/releases>
