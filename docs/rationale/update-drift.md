# Why `update-drift` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/update-drift.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

### Diff the installed file against EVERY tag and read which one MINIMISES.  Every sentence in…

- Measured by an adopter across four tags — ⚠️ **and produced by comparing against the *template*, which v1.35.0 established is the wrong file.** Read them as an illustration of the minimise *shape*, not as evidence that any installer transforms:

## v1.43.0 — matcher 3, and the `bash -n` rung (#134, #135)

### Matcher 3: the connector-carried commit pin

Matcher 2 excludes letters between the repo name and the hash, deliberately — a 7-character hex
run otherwise matches inside an ordinary word. The consequence is that the form a human actually
writes is invisible:

```
Imported from `agent-ready-<name>` (vv/, commit d89ec62) and re-adapted   <- matcher 2: MISS
agent-ready-<name> @ d89ec62                                              <- matcher 2: hit
```

A repo carrying both is triaged off the machine-readable one and nobody notices; a repo carrying
only the prose form reads as unstamped. **The reconciliation caught it**, which is why this was a
matcher bug and not a method bug — the reconciliation was paying for the matcher.

**The design point**: letters are allowed between the *name* and the *connector*, because that is
where a filename or parenthetical sits. They are not allowed between the connector and the hash.
The hex-inside-a-word risk is about what precedes the **hash**.

**Both properties were ablated, not argued.** ⚠️ **A first draft of this table was wrong twice**
and both are corrected here: it announced "six positives and eight negative controls" over a
table that listed four and six; and it named the trailing ablation as *"without the trailing
`[^A-Za-z0-9]`"*, which returns **zero** false hits. The trailing gap only leaks when it is
WIDENED to the leading gap's permissiveness. Measured:

| trailing gap | `commitment` / `reviewed` / `referenced` |
|---|---|
| `[^A-Za-z0-9]{1,4}` (shipped) | 0 false hits |
| deleted entirely | 0 false hits |
| `[^0-9]{1,4}` | 0 false hits |
| `[^0-9]{0,40}` (the leading gap's shape) | **false hits** |

The corpus below is the full set — count the rows rather than trusting a headline:

| case | without `\b` | without the trailing `[^A-Za-z0-9]` | shipped form |
|---|---|---|---|
| `commit d89ec62` | hit | hit | hit |
| `pinned to a1b2c3d4` | hit | hit | hit |
| `rev 9f8e7d6`, `sha 0123456789abcdef` | hit | hit | hit |
| `sprev d89ec62`, `href d89ec62` | **false hit** | — | silent |
| `commitment deadbeef01` | — | **false hit** | silent |
| `reviewed d89ec62`, `referenced deadbeef01` | — | **false hit** | silent |
| `deadbeefed` inside a word | silent | silent | silent |

### ⚠️ The portability constraint that decided the syntax

The first correct form used `(^|[^A-Za-z])` as the leading boundary. It is right under GNU grep
3.12 and **ugrep 7.8.4 refuses it**:

```
ugrep: error: error at position 1000
){1,4}[0-9a-f]{7,40}
                    \___exceeds complexity limits
```

Non-zero exit, no output — and inside the step's `2>/dev/null` that is **indistinguishable from
"no pins found"**. `\b` is accepted by both engines and returns identically (6/6 positives,
0/8 negatives on each). This is #189's class caught during authoring rather than after: `grep`
on the machine where this was written is a shell function shimming to ugrep.

### The connector list is the acknowledged weak part

`commit|rev|sha|ref|pinned to` are the shapes actually observed. A pin written *«fixed at»* or
*«as of»* is invisible to all three matchers. This is exactly the "classes I thought of" sample
the framework keeps getting caught by, which is why the negative controls outnumber the positives
and why the reconciliation stays non-optional.

### The `bash -n` rung (#135)

Lint rule 11 covers the fenced blocks *this repo* ships. It structurally cannot cover an
adopter's: `review-changes` is carried project-local by some adopters, a re-mapped copy is not
byte-comparable to anything upstream, and upstream lint runs upstream. An adopter measured the
block they were being asked to adopt at each version they could have taken it from — `bash -n`
failed at v1.31.0 and v1.36.1, and parsed at v1.37.0. Anyone adopting during that window — v1.31.0 through
v1.36.1, NINE tags once the v1.34.x point releases are counted, and a first draft of this
paragraph said eight — imported a block that dies with a shell error and prints nothing, which is
indistinguishable from a clean run — the failure Step 1.5 exists to prevent, one level up.

Marker presence says the text arrived. It says nothing about whether the block runs. **This rung
is the only arm of the problem that does not depend on the framework.**
