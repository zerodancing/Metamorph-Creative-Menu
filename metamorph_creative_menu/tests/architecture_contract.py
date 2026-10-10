from pathlib import Path
import re
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
failures = []


def fail(message):
    failures.append(message)


def read(path):
    return path.read_text(errors='replace')


# These checks intentionally protect only architecture boundaries that have runtime
# consequences. They do NOT prescribe file names inside a feature, line counts, local
# variable names, helper names, or a particular implementation of a mechanic.
required_roots = (
    'files/core',
    'files/platform/noita',
    'files/integrations/ew',
    'files/features',
    'files/ui',
    'files/diagnostics',
    'files/qa',
)
for relative in required_roots:
    if not (root / relative).is_dir():
        fail(f'missing architecture layer: {relative}')

# Historical ownership-by-history directories are deliberately gone. Their return would
# make it ambiguous where a gameplay/network bug belongs.
for relative in ('files/editors', 'files/forms', 'files/entities', 'files/ew_bridge', 'files/compat'):
    if (root / relative).exists():
        fail(f'obsolete architecture layer returned: {relative}')

# Documentation is documentation, never executable regression data.
if not (root / 'README.txt').is_file():
    fail('root README.txt is missing')
if not (root / 'tests/TESTING.txt').is_file():
    fail('tests/TESTING.txt is missing')
for test_path in sorted((root / 'tests').glob('*')):
    if test_path.suffix not in {'.py', '.lua'}:
        continue
    source = read(test_path)
    if 'README.txt' in source or 'TESTING.txt' in source:
        # This contract necessarily names the docs while enforcing the rule.
        if test_path.name != 'architecture_contract.py':
            fail(f'test depends on documentation text: {test_path.name}')

production_lua = {
    path.relative_to(root).as_posix(): path
    for path in (root / 'files').rglob('*.lua')
}
production_text = {relative: read(path) for relative, path in production_lua.items()}

# Import graph. We care about dependency direction and cycles, not the exact split of a
# feature into files.
import_pattern = re.compile(
    r'(?:dofile|dofile_once)\(\s*["\']mods/metamorph_creative_menu/([^"\']+)["\']\s*\)'
)
edges = {relative: set() for relative in production_lua}
for relative, source in production_text.items():
    for dependency in import_pattern.findall(source):
        if dependency in production_lua:
            edges[relative].add(dependency)

# Core must remain engine/network agnostic. Platform is the Noita boundary. Gameplay and
# integrations may depend on core/platform but never on UI/diagnostics/QA.
for relative, source in production_text.items():
    if relative.startswith('files/core/'):
        if re.search(r'mods/metamorph_creative_menu/files/(?:features|platform|integrations|ui|diagnostics|qa)/', source):
            fail(f'core depends on a higher layer: {relative}')
        if re.search(r'\b(?:Entity|Component|Game|Mod|Gui|Input|Globals)[A-Z][A-Za-z0-9_]*\s*\(', source):
            fail(f'core directly calls Noita API: {relative}')
    elif relative.startswith('files/platform/'):
        if re.search(r'mods/metamorph_creative_menu/files/(?:features|integrations|ui|diagnostics|qa)/', source):
            fail(f'platform depends on gameplay/network/UI layer: {relative}')
    elif relative.startswith('files/features/'):
        if re.search(r'mods/metamorph_creative_menu/files/(?:ui|diagnostics|qa)/', source):
            fail(f'feature depends on UI/diagnostics/QA: {relative}')
    elif relative.startswith('files/integrations/'):
        if re.search(r'mods/metamorph_creative_menu/files/(?:ui|diagnostics|qa)/', source):
            fail(f'integration depends on UI/diagnostics/QA: {relative}')

# UI is a presentation/input layer. It may call feature services and UI/platform helpers,
# but it must not implement the network protocol or low-level entity/component mutation.
ui_paths = [root / 'files/ui/menu_controller.lua', *sorted((root / 'files/ui/tabs').glob('*.lua'))]
for path in ui_paths:
    if not path.is_file():
        continue
    source = read(path)
    if 'mods/metamorph_creative_menu/files/integrations/ew/' in source:
        fail(f'UI directly imports EW integration: {path.relative_to(root)}')
    if 'quant.ew' in source or 'ew_flag_this_is_host' in source:
        fail(f'UI contains EW peer policy: {path.relative_to(root)}')
    if re.search(r'\b(?:Entity|Component)[A-Z][A-Za-z0-9_]*\s*\(', source):
        fail(f'UI directly calls Entity/Component API: {path.relative_to(root)}')

# The only gameplay-side direct EW peer check is the standalone companion AI VM, where
# it prevents duplicate simulation rather than restricting user rights.
for relative, source in production_text.items():
    if not relative.startswith('files/features/'):
        continue
    if ('quant.ew' in source or 'ew_flag_this_is_host' in source) and relative != 'files/features/companion/ai.lua':
        fail(f'EW peer policy leaked into gameplay feature: {relative}')

# No internal import cycles: with Noita's multiple Lua VMs, cycles turn load order into a
# hidden behavioral contract.
visiting = set()
visited = set()
stack = []


def visit(node):
    if node in visited:
        return
    if node in visiting:
        start = stack.index(node) if node in stack else 0
        fail('cyclic production dependency: ' + ' -> '.join(stack[start:] + [node]))
        return
    visiting.add(node)
    stack.append(node)
    for dependency in sorted(edges.get(node, ())):
        visit(dependency)
    stack.pop()
    visiting.remove(node)
    visited.add(node)


for module in sorted(production_lua):
    visit(module)

# Catch abandoned runtime files without requiring a particular module layout. Stable root
# registries, engine callback Lua files referenced by XML, and everything reachable by a
# literal mod path all count as inbound use.
all_runtime_sources = []
for path in root.rglob('*'):
    if path.is_file() and path.suffix in {'.lua', '.xml'} and 'tests' not in path.parts:
        all_runtime_sources.append((path, read(path)))

allowed_root_lua = {'item_registry.lua', 'creature_registry.lua'}
for path in sorted((root / 'files').rglob('*.lua')):
    relative = path.relative_to(root).as_posix()
    if path.parent == root / 'files' and path.name in allowed_root_lua:
        continue
    runtime_path = 'mods/metamorph_creative_menu/' + relative
    referenced = any(runtime_path in source for source_path, source in all_runtime_sources if source_path != path)
    if not referenced:
        fail(f'unreferenced production module: {relative}')

if failures:
    print('architecture_contract=FAIL')
    for message in failures:
        print(' -', message)
    raise SystemExit(1)

print(
    'architecture_contract=PASS '
    f'modules={len(production_lua)} dependencies={sum(len(v) for v in edges.values())}'
)
