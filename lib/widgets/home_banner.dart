import 'dart:async';

import 'package:flutter/material.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _bannerData = [
    {
      'image': 'assets/images/banner_1.jpg',
      'gradient': [const Color(0xFFFF9800), const Color(0xFFFF6F00)],
      'icon': Icons.account_balance_wallet,
      'title': 'Quản lý tài chính thông minh',
      'subtitle': 'Theo dõi chi tiêu hàng ngày một cách dễ dàng',
    },
    {
      'image': 'assets/images/banner_2.jpg',
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
      'icon': Icons.savings,
      'title': 'Tiết kiệm hiệu quả',
      'subtitle': 'Lập kế hoạch tài chính cho tương lai',
    },
    {
      'image': 'assets/images/banner_3.jpg',
      'gradient': [const Color(0xFF2196F3), const Color(0xFF1565C0)],
      'icon': Icons.analytics,
      'title': 'Báo cáo chi tiết',
      'subtitle': 'Phân tích chi tiêu với biểu đồ trực quan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _bannerData.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Banner slider
          Container(
            height: MediaQuery.of(context).size.width * 0.5, // Tỷ lệ 2:1
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _bannerData.length,
                itemBuilder: (context, index) {
                  final bannerItem = _bannerData[index];
                  return GestureDetector(
                    onTap: () {
                      // Có thể thêm logic điều hướng khi tap vào banner
                      debugPrint('Banner ${index + 1} tapped');
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image với fallback
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: bannerItem['gradient'],
                            ),
                          ),
                          child: Image.asset(
                            bannerItem['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback hiển thị icon và gradient khi ảnh lỗi
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: bannerItem['gradient'],
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment(0, -0.25), // Di chuyển icon lên khoảng 2/4 chiều cao
                                  child: Icon(
                                    bannerItem['icon'],
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Overlay gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        // Text content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bannerItem['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                              Text(
                                bannerItem['subtitle']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
