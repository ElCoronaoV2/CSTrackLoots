import 'package:flutter/material.dart';

import '../models/cs_account.dart';
import '../theme/app_theme.dart';
import 'cut_corner_card.dart';

enum DropState { pending, obtained, missed }

extension CsAccountDrop on CsAccount {
  DropState get dropState {
    if (dropObtainedThisWeek) return DropState.obtained;
    if (dropMissedThisWeek) return DropState.missed;
    return DropState.pending;
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.onRegisterDrop,
    required this.onTap,
    required this.onDelete,
  });

  final CsAccount account;
  final VoidCallback onRegisterDrop;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = account.dropState;
    final color = switch (state) {
      DropState.obtained => AppTheme.csGreen,
      DropState.pending => AppTheme.csOrange,
      DropState.missed => AppTheme.csRed,
    };
    final label = switch (state) {
      DropState.obtained => 'Drop conseguido',
      DropState.pending => 'Drop pendiente',
      DropState.missed => 'Drop perdido',
    };
    final icon = switch (state) {
      DropState.obtained => Icons.check_circle,
      DropState.pending => Icons.flag,
      DropState.missed => Icons.cancel,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: CutCornerCard(
        color: AppTheme.bgCard,
        borderColor: color.withValues(alpha: 0.45),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        cut: 12,
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.alias,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (account.premierRating > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 14, color: AppTheme.csOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${account.premierRating}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onRegisterDrop,
            style: FilledButton.styleFrom(
              backgroundColor: state == DropState.obtained
                  ? AppTheme.borderStrong
                  : AppTheme.csOrange,
              foregroundColor: state == DropState.obtained ? Colors.white70 : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: Icon(state == DropState.obtained ? Icons.edit : Icons.add, size: 16),
            label: Text(state == DropState.obtained ? 'Modificar' : 'Drop'),
          ),
        ],
      ),
      ),
    );
  }
}
