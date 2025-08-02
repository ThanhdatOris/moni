/// Profile Header Widget - Hiển thị avatar, tên và thông tin user
/// Được tách từ ProfileScreen để cải thiện maintainability

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../edit_profile_screen.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserModel? userModel;
  final bool isLoading;

  const ProfileHeaderWidget({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingHeader();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary, // Orange
            AppColors.primaryDark, // Deep Orange
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with white border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildAvatar(),
            ),
            const SizedBox(width: 12),
            // Name and Email Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    _getDisplayName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    _getDisplayEmail(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Account type badge
                  _buildAccountTypeBadge(),
                ],
              ),
            ),
            // Edit profile button
            _buildEditButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.grey200,
            AppColors.grey300,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Loading avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
            const SizedBox(width: 12),
            // Loading text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            // Loading edit button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoURL = userModel?.photoUrl ?? currentUser?.photoURL;
    final displayName = _getDisplayName();

    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoURL != null && photoURL.isNotEmpty
            ? NetworkImage(photoURL)
            : null,
        child: photoURL == null || photoURL.isEmpty
            ? _buildDefaultAvatar(displayName)
            : null,
      ),
    );
  }

  Widget _buildDefaultAvatar(String displayName) {
    final initials = _getInitials(displayName);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _getAccountType(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          icon: Icon(
            Icons.edit,
            color: AppColors.primary,
            size: 16,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Chỉnh sửa hồ sơ',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayName() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return userModel?.name ?? 
           currentUser?.displayName ?? 
           'Người dùng';
  }

  String _getDisplayEmail() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return userModel?.email ?? 
           currentUser?.email ?? 
           'email@example.com';
  }

  String _getAccountType() {
    // Logic to determine account type
    // TODO: Implement premium status when UserModel has isPremium field
    // if (userModel?.isPremium == true) {
    //   return 'Premium';
    // }
    return 'Miễn phí';
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }
}

/// Enhanced Profile Header with additional features
class EnhancedProfileHeaderWidget extends StatelessWidget {
  final UserModel? userModel;
  final bool isLoading;
  final VoidCallback? onEditPressed;
  final VoidCallback? onAvatarPressed;

  const EnhancedProfileHeaderWidget({
    super.key,
    required this.userModel,
    this.isLoading = false,
    this.onEditPressed,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAvatarPressed,
      child: ProfileHeaderWidget(
        userModel: userModel,
        isLoading: isLoading,
      ),
    );
  }
}

/// Profile Header Statistics Widget
class ProfileStatsWidget extends StatelessWidget {
  final int totalTransactions;
  final double totalSavings;
  final int daysActive;
  final bool isLoading;

  const ProfileStatsWidget({
    super.key,
    required this.totalTransactions,
    required this.totalSavings,
    required this.daysActive,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingStats();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Giao dịch',
              totalTransactions.toString(),
              Icons.receipt_long,
              AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.grey200),
          Expanded(
            child: _buildStatItem(
              'Tiết kiệm',
              '${(totalSavings / 1000000).toStringAsFixed(1)}M',
              Icons.savings,
              AppColors.success,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.grey200),
          Expanded(
            child: _buildStatItem(
              'Ngày sử dụng',
              daysActive.toString(),
              Icons.calendar_today,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
} 