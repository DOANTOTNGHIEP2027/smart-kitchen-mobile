/// Dữ liệu khởi tạo cho Demo Mode.
///
/// Mọi map dùng key wire-format của REST API. [DemoBackendAdapter] tạo bản sao
/// mutable từ các fixture này, vì vậy thao tác tạo/sửa/xoá trong bản demo không
/// làm thay đổi dữ liệu gốc.
abstract final class DemoFixtures {
  static const String householdId = 'demo-household-0001';
  static const String ownerId = 'demo-user-0001';

  static const List<Map<String, dynamic>> allergens = <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'name': 'Đậu phộng'},
    <String, dynamic>{'id': 2, 'name': 'Sữa'},
    <String, dynamic>{'id': 3, 'name': 'Trứng'},
    <String, dynamic>{'id': 4, 'name': 'Hải sản có vỏ'},
    <String, dynamic>{'id': 5, 'name': 'Gluten'},
  ];

  static Map<String, dynamic> healthProfile() => <String, dynamic>{
        'userId': ownerId,
        'targetDailyCalories': 1800,
        'dietType': 'NONE',
        'heightCm': 165.0,
        'weightKg': 58.0,
        'updatedAt': '2026-09-20T08:00:00.000Z',
        'allergens': <Map<String, dynamic>>[allergens[0]],
      };

  static List<Map<String, dynamic>> inventory() => <Map<String, dynamic>>[
        _inventoryItem(
          id: 'demo-inventory-ca-loc',
          name: 'Cá lóc',
          quantity: 0.6,
          unit: 'KG',
          category: 'Thịt cá',
          expiryDate: '2026-09-22',
          lowStockThreshold: 0.3,
        ),
        _inventoryItem(
          id: 'demo-inventory-ca-chua',
          name: 'Cà chua',
          quantity: 4,
          unit: 'QUẢ',
          category: 'Rau củ',
          expiryDate: '2026-09-24',
          lowStockThreshold: 2,
        ),
        _inventoryItem(
          id: 'demo-inventory-gao',
          name: 'Gạo',
          quantity: 2,
          unit: 'KG',
          category: 'Thực phẩm khô',
          lowStockThreshold: 0.5,
        ),
      ];

  static List<Map<String, dynamic>> suggestions() =>
      <Map<String, dynamic>>[
        <String, dynamic>{
          'recipeId': 'demo-recipe-ca-kho',
          'recipeName': 'Cá lóc kho tộ',
          'confidence': 0.93,
          'kbRecipeId': 'kb-ca-kho-to',
          'source': 'GENERATED',
          'rankReason':
              'Ưu tiên dùng cá lóc sắp đến hạn và phù hợp mục tiêu năng lượng của gia đình.',
          'tradeoffNote': 'Cần bổ sung nước dừa nếu trong kho chưa có.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Nước dừa',
              'quantity': 200.0,
              'unit': 'ML',
              'role': 'SECONDARY',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'INGREDIENT_RULE',
        },
        <String, dynamic>{
          'recipeId': 'demo-recipe-canh-chua',
          'recipeName': 'Canh chua cá lóc',
          'confidence': 0.88,
          'kbRecipeId': 'kb-canh-chua-ca-loc',
          'source': 'KB',
          'rankReason':
              'Dùng được cá lóc và cà chua sẵn có, món nhẹ phù hợp cho bữa trưa.',
          'tradeoffNote': 'Cần thêm me và giá đỗ để đủ vị.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Me chua',
              'quantity': 30.0,
              'unit': 'G',
              'role': 'SEASONING',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'INGREDIENT_RULE',
        },
        <String, dynamic>{
          'recipeId': 'demo-recipe-com-ga',
          'recipeName': 'Cơm gà áp chảo',
          'confidence': 0.75,
          'kbRecipeId': 'kb-com-ga-ap-chao',
          'source': 'KB',
          'rankReason':
              'Phương án nhanh khi cần một bữa no, có thể dùng gạo đang có trong kho.',
          'tradeoffNote': 'Chưa kiểm chứng đầy đủ dị ứng cho công thức này.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Ức gà',
              'quantity': 400.0,
              'unit': 'G',
              'role': 'MAIN',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'UNVERIFIED',
        },
      ];

  static Map<String, dynamic> recipe(String recipeId) {
    final recipes = <String, Map<String, dynamic>>{
      'demo-recipe-ca-kho': <String, dynamic>{
        'id': 'demo-recipe-ca-kho',
        'recipeName': 'Cá lóc kho tộ',
        'description':
            'Món kho đậm đà, thơm nước dừa; phù hợp cho bữa cơm gia đình.',
        'ingredients': <String>[
          'Cá lóc',
          'Nước dừa',
          'Nước mắm',
          'Tiêu và hành lá',
        ],
        'prepTimeMinutes': 40,
        'calories': 430,
        'tags': <String>['Món Việt', 'Món kho'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25367356',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Làm sạch cá lóc, cắt khúc và ướp với nước mắm, tiêu.',
            'duration_minutes': 10,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Thắng nước màu rồi cho cá vào đảo nhẹ.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Thêm nước dừa, kho lửa nhỏ đến khi nước sánh lại.',
            'duration_minutes': 25,
          },
        ],
      },
      'demo-recipe-canh-chua': <String, dynamic>{
        'id': 'demo-recipe-canh-chua',
        'recipeName': 'Canh chua cá lóc',
        'description':
            'Canh chua thanh nhẹ với cá, cà chua và vị me; dễ ăn trong bữa trưa.',
        'ingredients': <String>[
          'Cá lóc',
          'Cà chua',
          'Me chua',
          'Rau thơm',
        ],
        'prepTimeMinutes': 30,
        'calories': 280,
        'tags': <String>['Món Việt', 'Canh'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/26161349',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Đun nước, cho me chua vào dằm lấy vị.',
            'duration_minutes': 8,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Cho cá và cà chua vào nấu chín.',
            'duration_minutes': 12,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Nêm lại, thêm rau thơm rồi tắt bếp.',
            'duration_minutes': 3,
          },
        ],
      },
      'demo-recipe-com-ga': <String, dynamic>{
        'id': 'demo-recipe-com-ga',
        'recipeName': 'Cơm gà áp chảo',
        'description':
            'Bữa cơm nhanh gọn với gà áp chảo vàng thơm, dùng cùng cơm và rau.',
        'ingredients': <String>[
          'Ức gà',
          'Gạo',
          'Rau củ',
          'Muối và tiêu',
        ],
        'prepTimeMinutes': 25,
        'calories': 520,
        'tags': <String>['Món Việt', 'Nhanh gọn'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25641161',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Ướp ức gà với một ít muối và tiêu.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Áp chảo gà vàng đều hai mặt.',
            'duration_minutes': 15,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Cắt gà, dùng cùng cơm nóng và rau.',
            'duration_minutes': 3,
          },
        ],
      },
    };
    return Map<String, dynamic>.from(
      recipes[recipeId] ?? recipes['demo-recipe-ca-kho']!,
    );
  }

  static Map<String, dynamic> mealPlan(String weekStart) {
    final monday = DateTime.parse('${weekStart}T00:00:00Z');
    final slots = <Map<String, dynamic>>[];
    for (var day = 0; day < 7; day++) {
      final date = monday.add(Duration(days: day));
      final dateText = _dateOnly(date);
      for (final mealTime in <String>['BREAKFAST', 'LUNCH', 'DINNER']) {
        slots.add(<String, dynamic>{
          'id': 'demo-slot-$dateText-$mealTime',
          'slotDate': dateText,
          'mealTime': mealTime,
          'dishes': <Map<String, dynamic>>[],
        });
      }
    }
    return <String, dynamic>{
      'id': 'demo-plan-$weekStart',
      'householdId': householdId,
      'weekStart': weekStart,
      'slots': slots,
    };
  }

  static Map<String, dynamic> _inventoryItem({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    String? category,
    String? expiryDate,
    double? lowStockThreshold,
  }) =>
      <String, dynamic>{
        'id': id,
        'householdId': householdId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'displayQuantity': quantity,
        'displayUnit': unit,
        'lowStockThreshold': lowStockThreshold,
        'expiryDate': expiryDate,
        'note': null,
        'version': 1,
        'isLowStock': lowStockThreshold != null && quantity <= lowStockThreshold,
        'isExpiringSoon': expiryDate == '2026-09-22',
        'createdBy': ownerId,
        'createdAt': '2026-09-20T08:00:00.000Z',
        'updatedAt': '2026-09-20T08:00:00.000Z',
      };

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
