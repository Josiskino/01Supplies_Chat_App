import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/fixtures/conversation_fixtures.dart';
import '../../shared/models/conversation_view_data.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import '../../widgets/search/custom_search_bar.dart';

/// Annuaire des employés joignables par message.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactProfileData> get _filteredEmployees {
    final normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return ConversationFixtures.employees;

    return ConversationFixtures.employees.where((employee) {
      final searchable = _normalize(
        [
          employee.name,
          employee.role,
          employee.phone,
          employee.email,
          employee.location,
        ].whereType<String>().join(' '),
      );
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final employees = _filteredEmployees;

    return PlatformPage(
      title: l10n.contactsTitle,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: DesignTokens.spaceM,
                bottom: DesignTokens.spaceS,
              ),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Rechercher un employé',
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (value) => setState(() => _query = value),
              ),
            ),
          ),
          if (employees.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Iconsax.search_normal,
                title: 'Aucun employé trouvé',
                message: 'Essayez un nom, un rôle, une ville ou un numéro.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.paddingOf(context).bottom + DesignTokens.spaceM,
              ),
              sliver: SliverList.separated(
                itemCount: employees.length,
                separatorBuilder: (context, index) => Divider(
                  height: DesignTokens.borderWidthThin,
                  thickness: DesignTokens.borderWidthThin,
                  indent: DesignTokens.spaceL + DesignTokens.avatarL + 14,
                  color: DesignTokens.getBorderColor(
                    Theme.of(context).brightness == Brightness.dark,
                    opacity: 0.10,
                  ),
                ),
                itemBuilder: (context, index) {
                  return _EmployeeRow(employee: employees[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});

  final ContactProfileData employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = DesignTokens.getTextColorWithOpacity(context, 0.58);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceM,
          ),
          child: Row(
            children: [
              PresenceAvatar(
                name: employee.name,
                avatarUrl: employee.avatarUrl,
                presence: employee.presence,
                size: DesignTokens.avatarL,
              ),
              const SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Wrap(
                      spacing: DesignTokens.spaceM,
                      runSpacing: 2,
                      children: [
                        if (employee.phone != null)
                          _EmployeeMeta(
                            icon: Iconsax.call,
                            label: employee.phone!,
                          ),
                        if (employee.location != null)
                          _EmployeeMeta(
                            icon: Iconsax.location,
                            label: employee.location!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceM),
              Icon(
                Iconsax.message,
                size: DesignTokens.iconM,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeMeta extends StatelessWidget {
  const _EmployeeMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DesignTokens.getTextColorWithOpacity(context, 0.50);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
