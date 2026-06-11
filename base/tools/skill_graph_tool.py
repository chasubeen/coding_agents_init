#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "in",
    "is",
    "it",
    "of",
    "on",
    "or",
    "that",
    "the",
    "to",
    "with",
    "의",
    "및",
    "이",
    "를",
    "에",
}

SCALAR_RE = re.compile(r"^(?P<key>[A-Za-z0-9_-]+):\s*(?P<value>.*)$")


@dataclass
class Note:
    path: Path
    rel_path: Path
    frontmatter: dict[str, Any]
    body: str

    @property
    def note_id(self) -> str:
        return str(self.frontmatter.get("id", self.rel_path.stem))

    @property
    def title(self) -> str:
        value = self.frontmatter.get("title")
        if isinstance(value, str) and value.strip():
            return value.strip()
        match = re.search(r"^#\s+(.+)$", self.body, re.MULTILINE)
        return match.group(1).strip() if match else self.rel_path.stem

    @property
    def note_type(self) -> str:
        value = self.frontmatter.get("note_type")
        if isinstance(value, str) and value.strip():
            return value.strip()
        return self.rel_path.parts[0] if self.rel_path.parts else "note"

    @property
    def status(self) -> str:
        value = self.frontmatter.get("status")
        return value if isinstance(value, str) and value.strip() else "planned"

    def keywords(self) -> set[str]:
        explicit = {
            normalize_token(str(item))
            for item in ensure_list(self.frontmatter.get("keywords", []))
            if normalize_token(str(item))
        }
        headings = {
            normalize_token(token)
            for heading in re.findall(r"^#{1,2}\s+(.+)$", self.body, re.MULTILINE)
            for token in tokenize(heading)
            if normalize_token(token)
        }
        path_tokens = {
            normalize_token(token)
            for part in self.rel_path.with_suffix("").parts
            for token in tokenize(part)
            if normalize_token(token)
        }
        return explicit | headings | path_tokens


def normalize_token(token: str) -> str:
    cleaned = re.sub(r"[^0-9A-Za-z가-힣_-]", "", token).strip("_- ").lower()
    if not cleaned or cleaned in STOPWORDS or len(cleaned) <= 1:
        return ""
    return cleaned


def tokenize(text: str) -> list[str]:
    return [token for token in re.split(r"[\s_/,:()\[\]{}.-]+", text) if token]


def ensure_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    return [value]


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---\n"):
        return {}, text

    lines = text.splitlines()
    closing_index = None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            closing_index = idx
            break
    if closing_index is None:
        return {}, text

    fm_lines = lines[1:closing_index]
    body = "\n".join(lines[closing_index + 1 :])
    return parse_simple_yaml(fm_lines), body


def parse_simple_yaml(lines: list[str]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    i = 0
    while i < len(lines):
        raw = lines[i]
        if not raw.strip():
            i += 1
            continue
        match = SCALAR_RE.match(raw)
        if not match:
            i += 1
            continue
        key = match.group("key")
        value = match.group("value").strip()
        if value:
            result[key] = parse_scalar(value)
            i += 1
            continue

        child_indent = leading_spaces(raw) + 2
        items: list[Any] = []
        nested: dict[str, list[Any]] = {}
        i += 1
        while i < len(lines):
            child = lines[i]
            if not child.strip():
                i += 1
                continue
            indent = leading_spaces(child)
            if indent < child_indent:
                break
            stripped = child.strip()
            if stripped.startswith("- "):
                items.append(parse_scalar(stripped[2:].strip()))
                i += 1
                continue
            nested_match = SCALAR_RE.match(stripped)
            if nested_match and nested_match.group("value").strip() != "":
                nested_key = nested_match.group("key")
                parsed_value = parse_scalar(nested_match.group("value").strip())
                nested[nested_key] = ensure_list(parsed_value)
                i += 1
                continue
            if nested_match and nested_match.group("value").strip() == "":
                nested_key = nested_match.group("key")
                nested_items: list[Any] = []
                i += 1
                while i < len(lines):
                    nested_line = lines[i]
                    if not nested_line.strip():
                        i += 1
                        continue
                    nested_indent = leading_spaces(nested_line)
                    if nested_indent < indent + 2:
                        break
                    nested_stripped = nested_line.strip()
                    if nested_stripped.startswith("- "):
                        nested_items.append(parse_scalar(nested_stripped[2:].strip()))
                    i += 1
                nested[nested_key] = nested_items
                continue
            i += 1
        if nested:
            result[key] = nested
        else:
            result[key] = items
    return result


def leading_spaces(text: str) -> int:
    return len(text) - len(text.lstrip(" "))


def parse_scalar(value: str) -> Any:
    if value == "[]":
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(part.strip()) for part in inner.split(",")]
    if value.startswith(("'", '"')) and value.endswith(("'", '"')):
        return value[1:-1]
    return value


def dump_frontmatter(data: dict[str, Any]) -> str:
    lines = ["---"]
    for key, value in data.items():
        lines.extend(dump_yaml_value(key, value, indent=0))
    lines.append("---")
    return "\n".join(lines)


def dump_yaml_value(key: str, value: Any, indent: int) -> list[str]:
    prefix = " " * indent
    if isinstance(value, dict):
        lines = [f"{prefix}{key}:"]
        for sub_key, sub_value in value.items():
            lines.extend(dump_yaml_value(sub_key, sub_value, indent + 2))
        return lines
    if isinstance(value, list):
        if not value:
            return [f"{prefix}{key}: []"]
        lines = [f"{prefix}{key}:"]
        for item in value:
            lines.append(f"{' ' * (indent + 2)}- {item}")
        return lines
    return [f"{prefix}{key}: {value}"]


def render_note(frontmatter: dict[str, Any], body: str) -> str:
    return dump_frontmatter(frontmatter) + "\n\n" + body.strip("\n") + "\n"


def read_note(path: Path, root: Path) -> Note:
    text = path.read_text(encoding="utf-8")
    frontmatter, body = parse_frontmatter(text)
    return Note(
        path=path, rel_path=path.relative_to(root), frontmatter=frontmatter, body=body
    )


def list_notes(root: Path) -> list[Note]:
    notes: list[Note] = []
    for path in sorted(root.rglob("*.md")):
        if path.name in {
            "_TEMPLATE.md",
            "_LESSONS_TEMPLATE.md",
            "README.md",
            "schema.md",
            "index.md",
            "log.md",
        }:
            continue
        notes.append(read_note(path, root))
    return notes


def allowed_relations(root: Path) -> set[str]:
    schema_path = root / "schema.md"
    if not schema_path.exists():
        return set()
    text = schema_path.read_text(encoding="utf-8")
    return set(re.findall(r"`([a-z_]+)`", text))


def slugify(title: str) -> str:
    slug = re.sub(r"\s+", "-", title.strip())
    slug = re.sub(r"[^0-9A-Za-z가-힣_-]", "-", slug)
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug.lower() or "note"


def format_id(category: str, title: str, today: str) -> str:
    category_token = category.rstrip("s").replace("-", "_")
    return f"{category_token}-{today.replace('-', '')}-{slugify(title)}"


def update_frontmatter_for_create(
    note: Note, category: str, title: str, today: str
) -> Note:
    frontmatter = dict(note.frontmatter)
    frontmatter["id"] = (
        frontmatter.get("id")
        if frontmatter.get("id")
        not in {
            None,
            "",
            "YYYYMMDD_short-code",
            "lesson-topic-id",
            "feat-YYYYMMDD-short-title",
            "adr-YYYYMMDD-short-title",
            "idea-YYYYMMDD-short-title",
            "deliverable-YYYYMMDD-short-title",
        }
        else format_id(category, title, today)
    )
    frontmatter["title"] = title
    if not frontmatter.get("note_type") or str(frontmatter.get("note_type")).startswith(
        "["
    ):
        frontmatter["note_type"] = category.rstrip("s")
    if not frontmatter.get("status"):
        frontmatter["status"] = "planned"
    if "keywords" not in frontmatter:
        frontmatter["keywords"] = []
    if "sources" not in frontmatter:
        frontmatter["sources"] = []
    if "relations" not in frontmatter:
        frontmatter["relations"] = {"related_to": []}
    if (
        "last_verified" not in frontmatter
        or str(frontmatter.get("last_verified")) == "YYYY-MM-DD"
    ):
        frontmatter["last_verified"] = today
    if "confidence" not in frontmatter:
        frontmatter["confidence"] = "medium"
    body = note.body.replace("YYYY-MM-DD", today)
    body = body.replace("[작업명]", title)
    body = body.replace("[주제명]", title)
    body = body.replace("[기능명]", title)
    body = body.replace("[결정 제목]", title)
    body = body.replace("[아이디어명]", title)
    body = body.replace("[납품물명]", title)
    return Note(
        path=note.path, rel_path=note.rel_path, frontmatter=frontmatter, body=body
    )


def insert_catalog_entry(index_path: Path, note: Note) -> None:
    text = index_path.read_text(encoding="utf-8")
    catalog_headers = ["문서 ID", "문서", "note_type", "상태", "핵심 키워드"]
    catalog_row = format_row(catalog_headers, note)
    text = insert_row_into_named_section(
        text,
        heading="## 문서 카탈로그",
        row=catalog_row,
        fallback_headers=catalog_headers,
    )

    category_heading = f"### {note.rel_path.parts[0]}/"
    category_row = format_row(category_headers(text, category_heading), note)
    text = insert_row_into_named_section(
        text,
        heading=category_heading,
        row=category_row,
        fallback_headers=["문서", "상태", "키워드"],
    )

    timeline_headers = ["날짜", "문서", "요약"]
    timeline_row = format_row(timeline_headers, note)
    text = insert_row_into_named_section(
        text,
        heading="## 타임라인",
        row=timeline_row,
        fallback_headers=timeline_headers,
    )

    index_path.write_text(text, encoding="utf-8")


def format_keywords(note: Note) -> str:
    keywords = [
        str(item).strip()
        for item in ensure_list(note.frontmatter.get("keywords", []))
        if str(item).strip()
    ]
    return " ".join(f"`{keyword}`" for keyword in keywords) if keywords else "-"


def format_row(headers: list[str], note: Note) -> str:
    values = [column_value(header, note) for header in headers]
    return "| " + " | ".join(values) + " |"


def column_value(header: str, note: Note) -> str:
    normalized = header.strip().lower()
    if normalized == "날짜":
        return note_date(note)
    if normalized == "문서 id":
        return f"`{note.note_id}`"
    if normalized == "문서":
        return f"[{note.title}]({note.rel_path.as_posix()})"
    if normalized == "note_type":
        return note.note_type
    if normalized == "상태":
        return note.status
    if normalized in {"키워드", "핵심 키워드"}:
        return format_keywords(note)
    if normalized == "요약":
        summary = note.frontmatter.get("summary")
        return str(summary).strip() if summary else note.title
    if normalized == "phase":
        phase = note.frontmatter.get("phase")
        return str(phase).strip() if phase else "-"
    if normalized == "구분":
        kind = (
            note.frontmatter.get("kind")
            or note.frontmatter.get("source")
            or note.note_type
        )
        return str(kind).strip()
    return "-"


def category_headers(text: str, heading: str) -> list[str]:
    section = extract_section(text, heading)
    if section is None:
        return ["문서", "상태", "키워드"]
    table = first_table_headers(section)
    return table if table else ["문서", "상태", "키워드"]


def insert_row_into_named_section(
    text: str,
    heading: str,
    row: str,
    fallback_headers: list[str],
) -> str:
    section_bounds = find_section_bounds(text, heading)
    if section_bounds is None:
        return text
    start, end = section_bounds
    section = text[start:end]
    updated = insert_row_into_section(section, row, fallback_headers)
    return text[:start] + updated + text[end:]


def find_section_bounds(text: str, heading: str) -> tuple[int, int] | None:
    start = text.find(heading)
    if start == -1:
        return None
    rest = text[start + len(heading) :]
    match = re.search(r"\n##?\s+", rest)
    end = start + len(heading) + match.start() if match else len(text)
    return start, end


def extract_section(text: str, heading: str) -> str | None:
    bounds = find_section_bounds(text, heading)
    if bounds is None:
        return None
    start, end = bounds
    return text[start:end]


def first_table_headers(section: str) -> list[str] | None:
    lines = section.splitlines()
    for idx in range(len(lines) - 1):
        if (
            lines[idx].startswith("|")
            and idx + 1 < len(lines)
            and re.match(r"^\|[-| ]+\|$", lines[idx + 1])
        ):
            return [cell.strip() for cell in lines[idx].strip().strip("|").split("|")]
    return None


def insert_row_into_section(section: str, row: str, fallback_headers: list[str]) -> str:
    if row in section:
        return section

    lines = section.splitlines()
    table_index = first_table_index(lines)
    if table_index is not None:
        insert_at = table_index + 2
        while (
            insert_at < len(lines)
            and lines[insert_at].startswith("|")
            and not lines[insert_at].startswith("| <!--")
        ):
            insert_at += 1
        lines.insert(insert_at, row)
        return "\n".join(lines)

    placeholder = "_(아직 없음)_"
    if placeholder in section:
        replacement = [
            table_header_line(fallback_headers),
            table_separator_line(fallback_headers),
            row,
        ]
        return section.replace(placeholder, "\n".join(replacement), 1)

    append_block = [
        "",
        table_header_line(fallback_headers),
        table_separator_line(fallback_headers),
        row,
    ]
    return section.rstrip() + "\n" + "\n".join(append_block) + "\n"


def first_table_index(lines: list[str]) -> int | None:
    for idx in range(len(lines) - 1):
        if lines[idx].startswith("|") and re.match(r"^\|[-| ]+\|$", lines[idx + 1]):
            return idx
    return None


def table_header_line(headers: list[str]) -> str:
    return "| " + " | ".join(headers) + " |"


def table_separator_line(headers: list[str]) -> str:
    return (
        "|"
        + "|".join(
            "-" * (len(header.strip()) if header.strip() else 3) for header in headers
        )
        + "|"
    )


def note_date(note: Note) -> str:
    match = re.match(r"(\d{4}-\d{2}-\d{2})_", note.rel_path.name)
    if match:
        return match.group(1)
    last_verified = note.frontmatter.get("last_verified")
    return str(last_verified).strip() if last_verified else "-"


def append_log(log_path: Path, action: str, note: Note) -> None:
    today = dt.date.today().isoformat()
    entry = (
        f"\n## [{today}] {action} | {note.title}\n"
        f"- note_id: `{note.note_id}`\n"
        f"- files: `{note.rel_path.as_posix()}`\n"
        f"- summary: auto-generated by skill_graph_tool\n"
    )
    text = (
        log_path.read_text(encoding="utf-8")
        if log_path.exists()
        else "# Skill Graph Log\n"
    )
    if f"note_id: `{note.note_id}`" in text and f"] {action} | {note.title}" in text:
        return
    log_path.write_text(text.rstrip() + "\n" + entry, encoding="utf-8")


def ensure_related_section(body: str) -> tuple[str, list[str]]:
    marker = "## 관련 노트"
    if marker not in body:
        body = body.rstrip() + "\n\n## 관련 노트\n"
    before, after = body.split(marker, 1)
    lines = after.splitlines()
    header_and_rest = lines[1:] if lines and not lines[0].strip() else lines
    section_lines: list[str] = []
    trailing: list[str] = []
    collecting = True
    for line in header_and_rest:
        if collecting and (line.startswith("## ") or line.startswith("### ")):
            collecting = False
        if collecting:
            section_lines.append(line)
        else:
            trailing.append(line)
    return before.rstrip() + "\n\n" + marker + "\n", section_lines + [
        "__TRAIL__"
    ] + trailing


def update_related_section(note: Note, linked: list[tuple[str, str, str]]) -> str:
    prefix, section_payload = ensure_related_section(note.body)
    split_index = section_payload.index("__TRAIL__")
    current_lines = section_payload[:split_index]
    trailing = section_payload[split_index + 1 :]
    manual_lines = [line for line in current_lines if not line.startswith("- [")]
    new_lines = [line for line in manual_lines if line.strip()]
    seen_auto: set[str] = set()
    for category, rel_path, title in linked:
        line = f"- [{category}] {rel_path} — {title}"
        if line not in seen_auto:
            new_lines.append(line)
            seen_auto.add(line)
    body_lines = prefix.rstrip().splitlines()
    rebuilt = "\n".join(body_lines + [""] + new_lines).rstrip() + "\n"
    if trailing:
        rebuilt += "\n" + "\n".join(trailing).rstrip() + "\n"
    return rebuilt


def relation_ids(note: Note, relation: str) -> list[str]:
    relations = note.frontmatter.get("relations", {})
    if not isinstance(relations, dict):
        return []
    return [str(item) for item in ensure_list(relations.get(relation, []))]


def set_relation(note: Note, relation: str, related_id: str) -> None:
    relations = note.frontmatter.setdefault("relations", {})
    if not isinstance(relations, dict):
        relations = {}
        note.frontmatter["relations"] = relations
    current = [str(item) for item in ensure_list(relations.get(relation, []))]
    if related_id not in current:
        current.append(related_id)
    relations[relation] = current


def replace_relation(note: Note, relation: str, related_ids: list[str]) -> None:
    relations = note.frontmatter.setdefault("relations", {})
    if not isinstance(relations, dict):
        relations = {}
        note.frontmatter["relations"] = relations
    relations[relation] = related_ids


def create_note(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve() / "skill_graph"
    template_path = root / args.category / "_TEMPLATE.md"
    if not template_path.exists():
        raise SystemExit(f"Template not found: {template_path}")
    title = args.title.strip()
    if not title:
        raise SystemExit("Title is required")
    today = dt.date.today().isoformat()
    filename = f"{today}_{slugify(title)}.md"
    destination = root / args.category / filename
    if destination.exists() and not args.force:
        raise SystemExit(f"File already exists: {destination}")
    template_note = read_note(template_path, root)
    new_note = update_frontmatter_for_create(
        Note(
            path=destination,
            rel_path=destination.relative_to(root),
            frontmatter=template_note.frontmatter,
            body=template_note.body,
        ),
        args.category,
        title,
        today,
    )
    destination.write_text(
        render_note(new_note.frontmatter, new_note.body), encoding="utf-8"
    )
    insert_catalog_entry(root / "index.md", new_note)
    append_log(root / "log.md", "ingest", new_note)
    if args.link:
        run_link(root, destination)
    print(destination.relative_to(Path(args.root).resolve()).as_posix())
    return 0


def run_link(root: Path, target: Path | None) -> int:
    notes = list_notes(root)
    allowed = allowed_relations(root)
    if "related_to" not in allowed:
        raise SystemExit("schema.md must define related_to")
    targets = {target.resolve()} if target else {note.path.resolve() for note in notes}
    related_map: dict[str, list[tuple[str, str, str]]] = {
        note.note_id: [] for note in notes
    }
    affected_ids: set[str] = set()

    for note in notes:
        if note.path.resolve() not in targets:
            continue
        note_keywords = note.keywords()
        for other in notes:
            if other.path == note.path:
                continue
            overlap = note_keywords & other.keywords()
            if len(overlap) < 2:
                continue
            set_relation(note, "related_to", other.note_id)
            set_relation(other, "related_to", note.note_id)
            related_map[note.note_id].append(
                (
                    other.rel_path.parts[0],
                    relative_link(note.path.parent, other.path),
                    other.title,
                )
            )
            related_map[other.note_id].append(
                (
                    note.rel_path.parts[0],
                    relative_link(other.path.parent, note.path),
                    note.title,
                )
            )
            affected_ids.add(note.note_id)
            affected_ids.add(other.note_id)

    for note in notes:
        if note.note_id in affected_ids:
            note.body = update_related_section(
                note, sorted(related_map[note.note_id], key=lambda item: item[1])
            )
        if note.note_id not in affected_ids and note.path.resolve() not in targets:
            continue
        note.path.write_text(render_note(note.frontmatter, note.body), encoding="utf-8")
    return 0


def relative_link(base_dir: Path, other: Path) -> str:
    return Path(os.path.relpath(other, base_dir)).as_posix()


def link_notes(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve() / "skill_graph"
    target = Path(args.target).resolve() if args.target else None
    return run_link(root, target)


def sync_notes(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve() / "skill_graph"
    notes = list_notes(root)
    if not notes:
        print("SKILL_GRAPH_SYNC: PASS")
        print("Synced 0 note(s)")
        return 0

    selected_path = Path(args.target).resolve() if args.target else None
    targets = [
        note
        for note in notes
        if selected_path is None or note.path.resolve() == selected_path
    ]
    if selected_path and not targets:
        raise SystemExit(f"Target note not found: {selected_path}")

    overlap_map = compute_overlap_map(notes)
    affected_ids = compute_affected_ids(targets, notes, overlap_map)
    sync_related_links(notes, overlap_map, affected_ids)
    synced_notes = [
        note for note in notes if note.note_id in affected_ids or selected_path is None
    ]
    sync_index(root / "index.md", synced_notes)
    sync_log(root / "log.md", synced_notes)

    issues = lint_relations(root, synced_notes, {note.note_id: note for note in notes})
    issues.extend(
        lint_related_links(synced_notes, {note.note_id: note for note in notes})
    )
    issues.extend(lint_index(root / "index.md", synced_notes))
    issues.extend(lint_log(root / "log.md", synced_notes))
    if issues:
        print("SKILL_GRAPH_SYNC: FAIL")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("SKILL_GRAPH_SYNC: PASS")
    print(f"Synced {len(synced_notes)} note(s)")
    return 0


def compute_overlap_map(notes: list[Note]) -> dict[str, list[str]]:
    overlap_map = {note.note_id: [] for note in notes}
    for note in notes:
        note_keywords = note.keywords()
        for other in notes:
            if other.path == note.path:
                continue
            if len(note_keywords & other.keywords()) < 2:
                continue
            overlap_map[note.note_id].append(other.note_id)
    for note_id in overlap_map:
        overlap_map[note_id] = sorted(set(overlap_map[note_id]))
    return overlap_map


def compute_affected_ids(
    targets: list[Note], notes: list[Note], overlap_map: dict[str, list[str]]
) -> set[str]:
    if len(targets) == len(notes):
        return {note.note_id for note in notes}
    affected = {note.note_id for note in targets}
    for note in targets:
        affected.update(relation_ids(note, "related_to"))
        affected.update(overlap_map.get(note.note_id, []))
    return affected


def sync_related_links(
    notes: list[Note], overlap_map: dict[str, list[str]], affected_ids: set[str]
) -> None:
    by_id = {note.note_id: note for note in notes}
    for note in notes:
        if note.note_id not in affected_ids:
            continue
        related_ids = [
            related_id
            for related_id in overlap_map.get(note.note_id, [])
            if related_id in by_id
        ]
        replace_relation(note, "related_to", related_ids)
        linked = [
            (
                by_id[related_id].rel_path.parts[0],
                relative_link(note.path.parent, by_id[related_id].path),
                by_id[related_id].title,
            )
            for related_id in related_ids
        ]
        note.body = update_related_section(note, linked)
        note.path.write_text(render_note(note.frontmatter, note.body), encoding="utf-8")


def sync_index(index_path: Path, notes: list[Note]) -> None:
    text = index_path.read_text(encoding="utf-8")
    for note in notes:
        text = remove_note_rows_from_index(text, note)
    index_path.write_text(text, encoding="utf-8")
    for note in sorted(notes, key=timeline_sort_key, reverse=True):
        insert_catalog_entry(index_path, note)


def remove_note_rows_from_index(text: str, note: Note) -> str:
    catalog_heading = "## 문서 카탈로그"
    category_heading = f"### {note.rel_path.parts[0]}/"
    timeline_heading = "## 타임라인"
    text = remove_note_rows_from_section(text, catalog_heading, note)
    text = remove_note_rows_from_section(text, category_heading, note)
    text = remove_note_rows_from_section(text, timeline_heading, note)
    return text


def remove_note_rows_from_section(text: str, heading: str, note: Note) -> str:
    bounds = find_section_bounds(text, heading)
    if bounds is None:
        return text
    start, end = bounds
    section = text[start:end]
    filtered_lines = []
    note_link = f"]({note.rel_path.as_posix()})"
    for line in section.splitlines():
        stripped = line.strip()
        if (
            stripped.startswith("|")
            and not stripped.startswith("|-")
            and not stripped.startswith("| <!--")
        ):
            if f"`{note.note_id}`" in line or note_link in line:
                continue
        filtered_lines.append(line)
    updated = "\n".join(filtered_lines)
    return text[:start] + updated + text[end:]


def timeline_sort_key(note: Note) -> tuple[str, str]:
    return note_date(note), note.title.lower()


def sync_log(log_path: Path, notes: list[Note]) -> None:
    for note in notes:
        append_log(log_path, "sync", note)


def lint_notes(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve() / "skill_graph"
    notes = list_notes(root)
    by_id = {note.note_id: note for note in notes}
    selected_path = Path(args.target).resolve() if args.target else None
    targets = [
        note
        for note in notes
        if selected_path is None or note.path.resolve() == selected_path
    ]
    if selected_path and not targets:
        raise SystemExit(f"Target note not found: {selected_path}")

    issues: list[str] = []
    issues.extend(lint_duplicate_ids(notes))
    issues.extend(lint_relations(root, targets, by_id))
    issues.extend(lint_related_links(targets, by_id))
    issues.extend(lint_index(root / "index.md", targets))
    issues.extend(lint_log(root / "log.md", targets))
    if selected_path is None:
        issues.extend(lint_orphans(notes))

    if issues:
        print("SKILL_GRAPH_LINT: FAIL")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("SKILL_GRAPH_LINT: PASS")
    print(f"Checked {len(targets)} note(s)")
    return 0


def lint_duplicate_ids(notes: list[Note]) -> list[str]:
    seen: dict[str, list[Path]] = {}
    for note in notes:
        seen.setdefault(note.note_id, []).append(note.rel_path)
    issues: list[str] = []
    for note_id, paths in seen.items():
        if len(paths) > 1:
            joined = ", ".join(path.as_posix() for path in paths)
            issues.append(f"duplicate note id `{note_id}` in {joined}")
    return issues


def lint_relations(root: Path, notes: list[Note], by_id: dict[str, Note]) -> list[str]:
    allowed = allowed_relations(root)
    issues: list[str] = []
    for note in notes:
        relations = note.frontmatter.get("relations", {})
        if not isinstance(relations, dict):
            issues.append(f"{note.rel_path.as_posix()}: relations must be a mapping")
            continue
        for relation, targets in relations.items():
            if relation not in allowed:
                issues.append(
                    f"{note.rel_path.as_posix()}: unknown relation `{relation}`"
                )
                continue
            for related_id in ensure_list(targets):
                related_text = str(related_id)
                if related_text == note.note_id:
                    issues.append(
                        f"{note.rel_path.as_posix()}: self reference in `{relation}`"
                    )
                if related_text not in by_id:
                    issues.append(
                        f"{note.rel_path.as_posix()}: missing target `{related_text}` in `{relation}`"
                    )
    return issues


def lint_related_links(notes: list[Note], by_id: dict[str, Note]) -> list[str]:
    issues: list[str] = []
    for note in notes:
        expected = {
            f"- [{by_id[related_id].rel_path.parts[0]}] {relative_link(note.path.parent, by_id[related_id].path)} — {by_id[related_id].title}"
            for related_id in relation_ids(note, "related_to")
            if related_id in by_id
        }
        actual = extract_auto_related_lines(note.body)
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        for line in missing:
            issues.append(
                f"{note.rel_path.as_posix()}: missing related-note line `{line}`"
            )
        for line in extra:
            issues.append(
                f"{note.rel_path.as_posix()}: stale related-note line `{line}`"
            )
    return issues


def lint_index(index_path: Path, notes: list[Note]) -> list[str]:
    if not index_path.exists():
        return [f"missing index file `{index_path.as_posix()}`"]
    text = index_path.read_text(encoding="utf-8")
    issues: list[str] = []
    catalog_headers = ["문서 ID", "문서", "note_type", "상태", "핵심 키워드"]
    for note in notes:
        catalog_row = format_row(catalog_headers, note)
        if catalog_row not in text:
            issues.append(f"index.md: missing catalog row for `{note.note_id}`")
        category_heading = f"### {note.rel_path.parts[0]}/"
        headers = category_headers(text, category_heading)
        category_row = format_row(headers, note)
        section = extract_section(text, category_heading)
        if section is None:
            issues.append(f"index.md: missing section `{category_heading}`")
        elif category_row not in section:
            issues.append(
                f"index.md: missing category row for `{note.note_id}` in `{category_heading}`"
            )
    return issues


def lint_log(log_path: Path, notes: list[Note]) -> list[str]:
    if not log_path.exists():
        return [f"missing log file `{log_path.as_posix()}`"]
    text = log_path.read_text(encoding="utf-8")
    issues: list[str] = []
    for note in notes:
        if f"note_id: `{note.note_id}`" not in text:
            issues.append(f"log.md: missing entry for `{note.note_id}`")
    return issues


def lint_orphans(notes: list[Note]) -> list[str]:
    inbound: dict[str, int] = {note.note_id: 0 for note in notes}
    outbound: dict[str, int] = {note.note_id: 0 for note in notes}
    for note in notes:
        relations = note.frontmatter.get("relations", {})
        if not isinstance(relations, dict):
            continue
        for relation, targets in relations.items():
            for related_id in ensure_list(targets):
                related_text = str(related_id)
                outbound[note.note_id] += 1
                if related_text in inbound:
                    inbound[related_text] += 1
    issues: list[str] = []
    for note in notes:
        if inbound[note.note_id] == 0 and outbound[note.note_id] == 0:
            issues.append(f"orphan note `{note.note_id}` at {note.rel_path.as_posix()}")
    return issues


def extract_auto_related_lines(body: str) -> set[str]:
    marker = "## 관련 노트"
    if marker not in body:
        return set()
    _, section_payload = ensure_related_section(body)
    split_index = section_payload.index("__TRAIL__")
    current_lines = section_payload[:split_index]
    return {line.strip() for line in current_lines if line.startswith("- [")}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage skill_graph notes")
    parser.add_argument(
        "--root", default=".", help="Project root containing skill_graph/"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    create_parser = subparsers.add_parser(
        "create", help="Create a new note from template"
    )
    create_parser.add_argument("category")
    create_parser.add_argument("title")
    create_parser.add_argument("--force", action="store_true")
    create_parser.add_argument("--link", action="store_true")
    create_parser.set_defaults(func=create_note)

    link_parser = subparsers.add_parser("link", help="Link notes by keyword overlap")
    link_parser.add_argument("target", nargs="?")
    link_parser.set_defaults(func=link_notes)

    sync_parser = subparsers.add_parser("sync", help="Sync skill graph metadata")
    sync_parser.add_argument("target", nargs="?")
    sync_parser.set_defaults(func=sync_notes)

    lint_parser = subparsers.add_parser("lint", help="Lint skill graph integrity")
    lint_parser.add_argument("target", nargs="?")
    lint_parser.set_defaults(func=lint_notes)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
