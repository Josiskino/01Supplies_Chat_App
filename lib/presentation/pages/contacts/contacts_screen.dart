import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/providers/directory/directory_provider.dart';
import '../../../core/providers/messaging/support_provider.dart';
import '../../../domain/repository/messaging/support_repository.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/models/conversation_view_data.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import '../../widgets/search/custom_search_bar.dart';

/// Répertoire des interlocuteurs : clients et partenaires de la plateforme.
///
/// La liste est chargée en une fois et filtrée en mémoire — cf.
/// `contactsProvider` pour la raison.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Contact dont la conversation est en cours d'ouverture.
  ///
  /// La création passe par le réseau : sans repère, un appui sur un contact
  /// reste sans effet visible le temps de l'aller-retour, et l'utilisateur
  /// appuie une seconde fois.
  String? _opening;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ouvre — ou retrouve — la conversation directe avec ce contact.
  ///
  /// L'API déduplique les conversations `direct` : toucher deux fois le même
  /// contact rouvre le même fil au lieu d'en créer un second.
  Future<void> _openConversation(ContactProfileData contact) async {
    final userId = contact.userId;
    if (userId == null || userId.isEmpty) return;

    setState(() => _opening = userId);
    final result = await ref
        .read(openDirectConversationUseCaseProvider)
        .call(OpenDirectParams(userId));
    if (!mounted) return;
    setState(() => _opening = null);

    result.match(
      (failure) => ref
          .read(platformUiProvider)
          .overlays
          .notify(context: context, message: failure.message, isError: true),
      (conversation) => context.push(
        AppUiRoute.conversationDetailPath(conversation.id),
        extra: {'contactName': contact.name},
      ),
    );
  }

  List<ContactProfileData> _filter(List<ContactProfileData> source) {
    final normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return source;

    return source.where((employee) {
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
    final async = ref.watch(contactsProvider);

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
                hintText: 'Rechercher un client ou un partenaire',
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (value) => setState(() => _query = value),
              ),
            ),
          ),
          ...switch (async) {
            AsyncLoading() => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            AsyncError(:final error) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Iconsax.cloud_cross,
                  title: 'Répertoire indisponible',
                  message: error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            ],
            AsyncValue(:final value?) => _buildList(
              context,
              _filter(value.map(ContactProfileData.fromUser).toList()),
            ),
          },
        ],
      ),
    );
  }

  /// Liste filtrée, ou état vide quand la recherche ne rend rien.
  List<Widget> _buildList(
    BuildContext context,
    List<ContactProfileData> employees,
  ) {
    if (employees.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Iconsax.search_normal,
            title: 'Aucun contact trouvé',
            message: 'Essayez un nom, un rôle, un e-mail ou un numéro.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceM,
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
            final employee = employees[index];
            return _EmployeeRow(
              employee: employee,
              isOpening: _opening != null && _opening == employee.userId,
              onTap: () => _openConversation(employee),
            );
          },
        ),
      ),
    ];
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.employee,
    this.onTap,
    this.isOpening = false,
  });

  final ContactProfileData employee;
  final VoidCallback? onTap;

  /// La conversation est en cours d'ouverture : la ligne le montre plutôt que
  /// de rester inerte pendant l'aller-retour réseau.
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = DesignTokens.getTextColorWithOpacity(context, 0.58);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOpening ? null : onTap,
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
              // L'icône devient un indicateur le temps de l'aller-retour :
              // créer la conversation passe par le réseau, et une ligne inerte
              // se fait toucher une seconde fois.
              SizedBox(
                width: DesignTokens.iconM,
                height: DesignTokens.iconM,
                child: isOpening
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(
                        Iconsax.message,
                        size: DesignTokens.iconM,
                        color: theme.colorScheme.primary,
                      ),
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
