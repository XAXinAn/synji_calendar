import 'package:flutter/material.dart';

class FindPage extends StatelessWidget {
  const FindPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {
        'title': '图片上传',
        'color': 0xFFBBDEFB,
        'icon': Icons.image_outlined,
        'image': 'assets/images/image_commit.png',
      },
      {
        'title': '敬请期待',
        'color': 0xFFC8E6C9,
        'icon': Icons.more_horiz,
        'image': 'assets/images/more.png',
      },
    ];

    return Container(
      color: const Color(0xFFF7F8FA), // 统一背景色
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          final String? imagePath = feature['image'] as String?;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // TODO: 实现功能点击
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Color(feature['color'] as int).withOpacity(0.2), // 稍微淡化顶部背景
                      child: imagePath != null
                          ? Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                feature['icon'] as IconData,
                                size: 40,
                                color: Color(feature['color'] as int),
                              ),
                            )
                          : Icon(
                              feature['icon'] as IconData,
                              size: 40,
                              color: Color(feature['color'] as int),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
