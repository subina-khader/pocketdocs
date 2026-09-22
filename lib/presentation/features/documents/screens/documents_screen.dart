
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_list_tile.dart';
import 'document_details_screen.dart';

class DocumentsScreen extends StatefulWidget {
/// Optional category ID to apply when this screen opens.
final int? initialCategoryId;

const DocumentsScreen({
super.key,
this.initialCategoryId,
});

@override
State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
final _searchController = TextEditingController();

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
final provider = context.read<DocumentProvider>();

if (provider.categories.isEmpty) {
provider.loadCategories();
}

if (widget.initialCategoryId != null) {
provider.filterByCategory(widget.initialCategoryId);
}
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

String _categoryName(
DocumentProvider provider,
int? categoryId,
) {
if (categoryId == null) {
return 'All categories';
}

return provider.categoryNameForId(categoryId) ?? 'Unknown category';
}

@override
Widget build(BuildContext context) {
final provider = context.watch<DocumentProvider>();

return SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
children: [
const Text(
'Documents',
style: TextStyle(
fontSize: 27,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 5),

Text(
'Search, filter and organize your vault.',
style: TextStyle(
color: Theme.of(context).colorScheme.onSurfaceVariant,
fontSize: 12,
),
),

const SizedBox(height: 18),

TextField(
controller: _searchController,
onChanged: (value) {
provider.searchDocuments(value);
setState(() {});
},
decoration: InputDecoration(
hintText: 'Search documents...',
prefixIcon: const Icon(Icons.search_rounded),
suffixIcon: _searchController.text.isEmpty
? null
    : IconButton(
onPressed: () {
_searchController.clear();
provider.searchDocuments('');
setState(() {});
},
icon: const Icon(Icons.close_rounded),
),
),
),

const SizedBox(height: 12),

Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: () => _showCategoryFilter(
context,
provider,
),
icon: const Icon(Icons.filter_list_rounded),
label: Text(
_categoryName(
provider,
provider.selectedCategoryId,
),
),
),
),

const SizedBox(width: 10),

OutlinedButton.icon(
onPressed: () => _showSort(
context,
provider,
),
icon: const Icon(Icons.sort_rounded),
label: const Text('Sort'),
),
],
),

if (provider.selectedCategoryId != null ||
provider.searchQuery.isNotEmpty) ...[
const SizedBox(height: 8),
Align(
alignment: Alignment.centerLeft,
child: TextButton(
onPressed: () {
_searchController.clear();
provider.clearFilters();
setState(() {});
},
child: const Text('Clear filters'),
),
),
],

const SizedBox(height: 12),

if (provider.isLoading)
const Center(
child: Padding(
padding: EdgeInsets.all(40),
child: CircularProgressIndicator(),
),
)
else if (provider.errorMessage != null)
Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
Text(
provider.errorMessage!,
textAlign: TextAlign.center,
),

const SizedBox(height: 10),

FilledButton(
onPressed: provider.loadDocuments,
child: const Text('Retry'),
),
],
),
),
)
else if (provider.documents.isEmpty)
Card(
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
children: [
const Icon(
Icons.search_off_rounded,
size: 42,
),

const SizedBox(height: 10),

const Text(
'No matching documents',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 5),

Text(
'Try another search or category.',
style: TextStyle(
color: Theme.of(context)
    .colorScheme
    .onSurfaceVariant,
fontSize: 12,
),
),
],
),
),
)
else
...provider.documents.map(
(document) => Padding(
padding: const EdgeInsets.only(bottom: 10),
child: DocumentListTile(
document: document,
onTap: () async {
await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => DocumentDetailsScreen(
document: document,
),
),
);
},
),
),
),
],
),
);
}

Future<void> _showCategoryFilter(
BuildContext context,
DocumentProvider provider,
) async {
await showModalBottomSheet<void>(
context: context,
showDragHandle: true,
builder: (_) => SafeArea(
child: ListView(
shrinkWrap: true,
padding: const EdgeInsets.fromLTRB(
16,
4,
16,
20,
),
children: [
const Text(
'Filter by category',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 10),

ListTile(
leading: const Icon(
Icons.all_inclusive_rounded,
),
title: const Text('All categories'),
trailing: provider.selectedCategoryId == null
? const Icon(Icons.check_rounded)
    : null,
onTap: () {
provider.filterByCategory(null);
Navigator.pop(context);
},
),

...provider.categories.map(
(category) => ListTile(
leading: const Icon(
Icons.folder_outlined,
),
title: Text(category.name),
trailing:
provider.selectedCategoryId == category.id
? const Icon(Icons.check_rounded)
    : null,
onTap: () {
provider.filterByCategory(category.id);
Navigator.pop(context);
},
),
),
],
),
),
);
}

Future<void> _showSort(
BuildContext context,
DocumentProvider provider,
) async {
await showModalBottomSheet<void>(
context: context,
showDragHandle: true,
builder: (_) => SafeArea(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const ListTile(
title: Text(
'Sort documents',
style: TextStyle(
fontWeight: FontWeight.w800,
),
),
),

_sortTile(
provider,
DocumentSortOption.newest,
'Newest first',
),

_sortTile(
provider,
DocumentSortOption.oldest,
'Oldest first',
),

_sortTile(
provider,
DocumentSortOption.titleAscending,
'Title A–Z',
),

_sortTile(
provider,
DocumentSortOption.titleDescending,
'Title Z–A',
),

const SizedBox(height: 12),
],
),
),
);
}

Widget _sortTile(
DocumentProvider provider,
DocumentSortOption option,
String title,
) {
return ListTile(
title: Text(title),
trailing: provider.sortOption == option
? const Icon(Icons.check_rounded)
    : null,
onTap: () {
provider.sortDocuments(option);
Navigator.pop(context);
},
);
}
}

