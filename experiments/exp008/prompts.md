# EXP-008 prompts

Pinned with the backlog section. `{...}` is filled by the runner. A prompt edited after pinning
is a changed design.

**Launch condition, every step**: a fresh model call with **no tools and no project context**,
so nothing but this text reaches the model. Either an API call, or a CLI session started in an
empty directory outside any repo with tools disabled; a session started inside this repo would
load `CLAUDE.md`, the subject, and void the run. The runner records which was used and the model.

## 1. Probe writer (once)

The file is numbered with `exp008.py number`.

```
Below is a project instructions file for an AI coding agent, with line numbers.

Write 30 questions that a future agent session working in this project might need answered,
each answerable from this file alone. Rules:
- Each question must rest on specific lines. Give their line numbers as "evidence".
- At least 10 questions must have an exact identifier as their whole answer: a file path,
  script name, skill name, command or rule number, copied verbatim from the file. Mark them
  "exact": true and make "answer" that identifier alone.
- The rest have a short answer of one sentence or less; mark them "exact": false.
- Do not ask what general knowledge answers. Spread the questions across the whole file.
- Use a different evidence line for each question where you can.
- No question may contain the answer to another question.

Return only JSON: [{"id": "P01", "question": "...", "answer": "...", "evidence": [12],
"exact": true}, ...] with ids P01 to P30.

FILE:
{original with line numbers}
```

## 2. Pruner, blind (twice, separate sessions)

```
Below is a project instructions file that an AI coding agent loads at the start of every
session. Shorten it to between {lo} and {hi} bytes (57-60% of its {total} bytes).

Delete whole lines only. Do not rewrite, merge, reorder or add lines. Keep every heading and
every blank line. If you delete all rows of a table, also delete its header and separator rows;
if you delete all lines inside a code block, also delete its fence lines. Keep what a future
agent session most needs in order to act correctly in this project.

Return only the shortened file, with no commentary.

FILE:
{original}
```

## 3. Pruner, known (once)

As 2, with this paragraph inserted before `Return only`:

```
The shortened file will be tested with questions like the ones below, and with other questions
you are not shown.

{the 15 known questions, one per line, without answers}
```

## 4. Reader (three sessions per variant)

```
Below is a project instructions file for an AI coding agent, then some questions. Answer each
question from the file alone. If the file does not say, answer UNKNOWN. When the answer is a
path, name or command, give it exactly as written in the file.

Return only JSON: {"P01": "...", ..., "P30": "..."}

FILE:
{variant text, or "(the file is empty)"}

QUESTIONS:
{all 30, as "P01: question"}
```

## 5. Grader (once, over the pooled items)

```
Each item below has a question, a reference answer and a candidate answer. Mark the candidate
true if it gives the same substance as the reference, and false if it is wrong, missing, vague
or UNKNOWN. Extra correct detail does not make it false.

Return only JSON: {"<item>": true|false, ...} covering every item.

ITEMS:
{pool.json}
```
