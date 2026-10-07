
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_list_tile.dart';
import 'document_details_screen.dart';

class DocumentsScreen extends StatefulWidget {
/// Optional category ID to apply when this screen opens.
final int? initialCategoryId;

const DocumentsScreen({super.key, this.initialCategoryId});

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
provider.filterByCategories({
widget.initialCategoryId!,
});
}
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

String _categoryName(DocumentProvider provider, int? categoryId) {
if (categoryId == null) {
return 'All categories';
}

return provider.categoryNameForId(categoryId) ?? 'Unknown category';
}

String _categoryEmoji(DocumentProvider provider, int? categoryId) {
if (categoryId == null) {
return '▦';
}

return provider.categoryForId(categoryId)?.emoji ?? '📄';
}

String _categoryFilterLabel(DocumentProvider provider) {
final ids = provider.selectedCategoryIds;

if (ids.isEmpty) {
return 'All categories';
}

if (ids.length == 1) {
final category = provider.categoryForId(ids.first);
return category?.name ?? '1 category';
}

return '${ids.length} categories';
}

@override
Widget build(BuildContext context) {
final provider = context.watch<DocumentProvider>();
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

final hasFilters =
provider.selectedCategoryIds.isNotEmpty ||
provider.searchQuery.isNotEmpty;

return SafeArea(
child: CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: [
SliverPadding(
padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
sliver: SliverToBoxAdapter(
child: _buildHeader(context, provider),
),
),

SliverPadding(
padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
sliver: SliverToBoxAdapter(
child: _buildSearchField(context, provider),
),
),

SliverPadding(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
sliver: SliverToBoxAdapter(
child: _buildFilterRow(
context,
provider,
colorScheme,
),
),
),

if (hasFilters)
SliverPadding(
padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
sliver: SliverToBoxAdapter(
child: _buildActiveFilters(
context,
provider,
colorScheme,
),
),
),

SliverPadding(
padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
sliver: _buildContent(
context,
provider,
theme,
),
),
],
),
);
}

Widget _buildHeader(
BuildContext context,
DocumentProvider provider,
) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Row(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Documents',
style: theme.textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.8,
),
),
const SizedBox(height: 5),
Text(
'Everything you keep, right where you need it.',
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onSurfaceVariant,
fontSize: 12.5,
),
),
],
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 11,
vertical: 7,
),
decoration: BoxDecoration(
color: colorScheme.primaryContainer,
borderRadius: BorderRadius.circular(14),
),
child: Text(
'${provider.documents.length}',
style: TextStyle(
color: colorScheme.onPrimaryContainer,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
),
],
);
}

Widget _buildSearchField(
BuildContext context,
DocumentProvider provider,
) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return TextField(
controller: _searchController,
onChanged: (value) {
provider.searchDocuments(value);
setState(() {});
},
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText: 'Search your documents',
prefixIcon: Icon(
Icons.search_rounded,
color: colorScheme.onSurfaceVariant,
),
suffixIcon: _searchController.text.isEmpty
? null
    : IconButton(
tooltip: 'Clear search',
onPressed: () {
_searchController.clear();
provider.searchDocuments('');
setState(() {});
},
icon: const Icon(Icons.close_rounded),
),
filled: true,
fillColor: colorScheme.surfaceContainerHighest.withOpacity(.55),
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 15,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: BorderSide(
color: colorScheme.primary.withOpacity(.45),
width: 1.2,
),
),
),
);
}

Widget _buildFilterRow(
BuildContext context,
DocumentProvider provider,
ColorScheme colorScheme,
) {
final hasCategoryFilter =
provider.selectedCategoryIds.isNotEmpty;

final categoryLabel = _categoryFilterLabel(provider);

final categoryEmoji = provider.selectedCategoryIds.length == 1
? _categoryEmoji(
provider,
provider.selectedCategoryIds.first,
)
    : '▦';

return Row(
children: [
Expanded(
child: Material(
color: hasCategoryFilter
? colorScheme.primaryContainer
    : colorScheme.surfaceContainerHighest.withOpacity(.5),
borderRadius: BorderRadius.circular(15),
child: InkWell(
borderRadius: BorderRadius.circular(15),
onTap: () => _showCategoryFilter(
context,
provider,
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 11,
),
child: Row(
children: [
Text(
categoryEmoji,
style: const TextStyle(fontSize: 17),
),
const SizedBox(width: 8),
Expanded(
child: Text(
categoryLabel,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
color: hasCategoryFilter
? colorScheme.onPrimaryContainer
    : colorScheme.onSurface,
fontSize: 12.5,
fontWeight: FontWeight.w700,
),
),
),
Icon(
Icons.keyboard_arrow_down_rounded,
size: 19,
color: hasCategoryFilter
? colorScheme.onPrimaryContainer
    : colorScheme.onSurfaceVariant,
),
],
),
),
),
),
),

const SizedBox(width: 9),

Material(
color: colorScheme.surfaceContainerHighest.withOpacity(.5),
borderRadius: BorderRadius.circular(15),
child: InkWell(
borderRadius: BorderRadius.circular(15),
onTap: () => _showSort(
context,
provider,
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 11,
),
child: Row(
children: [
Icon(
Icons.swap_vert_rounded,
size: 19,
color: colorScheme.onSurfaceVariant,
),
const SizedBox(width: 5),
Text(
_sortLabel(provider.sortOption),
style: TextStyle(
color: colorScheme.onSurface,
fontSize: 12.5,
fontWeight: FontWeight.w700,
),
),
],
),
),
),
),
],
);
}

String _sortLabel(DocumentSortOption option) {
switch (option) {
case DocumentSortOption.newest:
return 'Newest';

case DocumentSortOption.oldest:
return 'Oldest';

case DocumentSortOption.titleAscending:
return 'A–Z';

case DocumentSortOption.titleDescending:
return 'Z–A';
}
}

Widget _buildActiveFilters(
BuildContext context,
DocumentProvider provider,
ColorScheme colorScheme,
) {
final selectedIds = provider.selectedCategoryIds.toList();

return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Wrap(
spacing: 7,
runSpacing: 7,
children: [
...selectedIds.map((id) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: colorScheme.primaryContainer.withOpacity(.65),
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
_categoryEmoji(provider, id),
style: const TextStyle(fontSize: 14),
),
const SizedBox(width: 5),
Text(
_categoryName(provider, id),
style: TextStyle(
color: colorScheme.onPrimaryContainer,
fontSize: 11,
fontWeight: FontWeight.w700,
),
),
],
),
);
}),

if (provider.searchQuery.isNotEmpty)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerHighest,
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.search_rounded,
size: 14,
color: colorScheme.onSurfaceVariant,
),
const SizedBox(width: 5),
ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 130,
),
child: Text(
provider.searchQuery,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
color: colorScheme.onSurface,
fontSize: 11,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
],
),
),

const SizedBox(width: 5),

TextButton(
onPressed: () {
_searchController.clear();
provider.clearFilters();
setState(() {});
},
style: TextButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 7),
minimumSize: Size.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
child: const Text(
'Clear',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
],
);
}

Widget _buildContent(
BuildContext context,
DocumentProvider provider,
ThemeData theme,
) {
if (provider.isLoading) {
return const SliverToBoxAdapter(
child: Padding(
padding: EdgeInsets.only(top: 70),
child: Center(
child: CircularProgressIndicator(),
),
),
);
}

if (provider.errorMessage != null) {
return SliverToBoxAdapter(
child: _buildErrorState(
context,
provider,
),
);
}

if (provider.documents.isEmpty) {
return SliverToBoxAdapter(
child: _buildEmptyState(context),
);
}

return SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final document = provider.documents[index];

return Padding(
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
);
},
childCount: provider.documents.length,
),
);
}

Widget _buildErrorState(
BuildContext context,
DocumentProvider provider,
) {
final colorScheme = Theme.of(context).colorScheme;

return Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: colorScheme.errorContainer.withOpacity(.35),
borderRadius: BorderRadius.circular(22),
),
child: Column(
children: [
Icon(
Icons.cloud_off_rounded,
size: 38,
color: colorScheme.error,
),
const SizedBox(height: 12),
Text(
'Something went wrong',
style: TextStyle(
color: colorScheme.onErrorContainer,
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 5),
Text(
provider.errorMessage!,
textAlign: TextAlign.center,
style: TextStyle(
color: colorScheme.onErrorContainer.withOpacity(.8),
fontSize: 12,
),
),
const SizedBox(height: 16),
FilledButton.tonal(
onPressed: provider.loadDocuments,
child: const Text('Try again'),
),
],
),
);
}

Widget _buildEmptyState(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Container(
margin: const EdgeInsets.only(top: 28),
padding: const EdgeInsets.fromLTRB(
28,
34,
28,
34,
),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerLow,
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: colorScheme.outlineVariant.withOpacity(.45),
),
),
child: Column(
children: [
Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: colorScheme.primaryContainer,
shape: BoxShape.circle,
),
child: Icon(
Icons.description_outlined,
size: 29,
color: colorScheme.primary,
),
),
const SizedBox(height: 16),
Text(
'No documents found',
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 6),
Text(
'Try changing your search or category filter.',
textAlign: TextAlign.center,
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onSurfaceVariant,
height: 1.4,
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
final tempSelected = <int>{
...provider.selectedCategoryIds,
};

await showModalBottomSheet<void>(
context: context,
showDragHandle: true,
isScrollControlled: true,
builder: (_) {
final colorScheme = Theme.of(context).colorScheme;

return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
20,
4,
20,
20,
),
child: StatefulBuilder(
builder: (context, setModalState) {
return Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Expanded(
child: Text(
'Filter by category',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
),
if (tempSelected.isNotEmpty)
TextButton(
onPressed: () {
setModalState(() {
tempSelected.clear();
});
},
child: const Text('Clear'),
),
],
),

const SizedBox(height: 4),

Text(
tempSelected.isEmpty
? 'Select one or more categories.'
    : '${tempSelected.length} categories selected',
style: TextStyle(
color: colorScheme.onSurfaceVariant,
fontSize: 12,
),
),

const SizedBox(height: 16),

Flexible(
child: ListView(
shrinkWrap: true,
children: [
_multiCategoryTile(
context,
emoji: '▦',
title: 'All categories',
selected: tempSelected.isEmpty,
onTap: () {
setModalState(() {
tempSelected.clear();
});
},
),

...provider.categories.map(
(category) {
final selected =
tempSelected.contains(category.id);

return _multiCategoryTile(
context,
emoji: category.emoji,
title: category.name,
selected: selected,
onTap: () {
if (category.id == null) {
return;
}

setModalState(() {
if (tempSelected.contains(
category.id,
)) {
tempSelected.remove(
category.id,
);
} else {
tempSelected.add(
category.id!,
);
}
});
},
);
},
),
],
),
),

const SizedBox(height: 14),

SizedBox(
width: double.infinity,
child: FilledButton(
onPressed: () {
provider.filterByCategories(
tempSelected,
);

Navigator.pop(context);
},
child: Text(
tempSelected.isEmpty
? 'Show all documents'
    : 'Apply filter',
),
),
),
],
);
},
),
),
);
},
);
}

Widget _multiCategoryTile(
BuildContext context, {
required String emoji,
required String title,
required bool selected,
required VoidCallback onTap,
}) {
final colorScheme = Theme.of(context).colorScheme;

return Padding(
padding: const EdgeInsets.only(bottom: 5),
child: Material(
color: selected
? colorScheme.primaryContainer
    : Colors.transparent,
borderRadius: BorderRadius.circular(15),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(15),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
child: Row(
children: [
Container(
width: 38,
height: 38,
alignment: Alignment.center,
decoration: BoxDecoration(
color: selected
? colorScheme.primary.withOpacity(.10)
    : colorScheme.surfaceContainerHighest,
borderRadius: BorderRadius.circular(11),
),
child: Text(
emoji,
style: const TextStyle(fontSize: 19),
),
),

const SizedBox(width: 12),

Expanded(
child: Text(
title,
style: TextStyle(
fontSize: 13,
fontWeight: selected
? FontWeight.w700
    : FontWeight.w500,
color: selected
? colorScheme.onPrimaryContainer
    : colorScheme.onSurface,
),
),
),

AnimatedContainer(
duration: const Duration(milliseconds: 150),
width: 22,
height: 22,
decoration: BoxDecoration(
color: selected
? colorScheme.primary
    : Colors.transparent,
borderRadius: BorderRadius.circular(7),
border: Border.all(
color: selected
? colorScheme.primary
    : colorScheme.outline,
width: 1.5,
),
),
child: selected
? const Icon(
Icons.check_rounded,
size: 16,
color: Colors.white,
)
    : null,
),
],
),
),
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
builder: (_) {
final colorScheme = Theme.of(context).colorScheme;

return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
20,
4,
20,
20,
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Sort documents',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 4),

Text(
'Choose how your documents are arranged.',
style: TextStyle(
color: colorScheme.onSurfaceVariant,
fontSize: 12,
),
),

const SizedBox(height: 16),

_sortTile(
provider,
DocumentSortOption.newest,
'Newest first',
Icons.arrow_downward_rounded,
),

_sortTile(
provider,
DocumentSortOption.oldest,
'Oldest first',
Icons.arrow_upward_rounded,
),

_sortTile(
provider,
DocumentSortOption.titleAscending,
'Title A–Z',
Icons.sort_by_alpha_rounded,
),

_sortTile(
provider,
DocumentSortOption.titleDescending,
'Title Z–A',
Icons.sort_by_alpha_rounded,
),
],
),
),
);
},
);
}

Widget _sortTile(
DocumentProvider provider,
DocumentSortOption option,
String title,
IconData icon,
) {
final selected = provider.sortOption == option;

return ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 4),
leading: Icon(
icon,
size: 21,
color: selected
? Theme.of(context).colorScheme.primary
    : Theme.of(context).colorScheme.onSurfaceVariant,
),
title: Text(
title,
style: TextStyle(
fontSize: 13,
fontWeight: selected
? FontWeight.w700
    : FontWeight.w500,
),
),
trailing: selected
? Icon(
Icons.check_circle_rounded,
color: Theme.of(context).colorScheme.primary,
size: 21,
)
    : null,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
onTap: () {
provider.sortDocuments(option);
Navigator.pop(context);
},
);
}
}
