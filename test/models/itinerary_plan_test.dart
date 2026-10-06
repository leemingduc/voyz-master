import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/itinerary_plan.dart';

void main() {
  group('ItineraryItem', () {
    test('parses new optional fields correctly', () {
      final json = {
        'time': '09:00 AM',
        'title': 'Chợ Đêm Phú Quốc',
        'description': 'Khu chợ đêm sầm uất với nhiều món ăn địa phương.',
        'icon': 'restaurant',
        'location': 'Thị trấn Dương Đông, Phú Quốc',
        'estimatedCost': '100.000 - 200.000 VNĐ',
        'tips': 'Nên thử hải sản nướng và kem cuộn.',
        'details':
            'Đến vào khoảng 18:30 để mua sắm hải sản tươi sống và đồ lưu niệm.',
      };

      final item = ItineraryItem.fromJson(json);
      expect(item.time, '09:00 AM');
      expect(item.title, 'Chợ Đêm Phú Quốc');
      expect(item.location, 'Thị trấn Dương Đông, Phú Quốc');
      expect(item.estimatedCost, '100.000 - 200.000 VNĐ');
      expect(item.tips, 'Nên thử hải sản nướng và kem cuộn.');
      expect(
        item.details,
        'Đến vào khoảng 18:30 để mua sắm hải sản tươi sống và đồ lưu niệm.',
      );
    });

    test('backward compatibility when new optional fields are null', () {
      final json = {
        'time': '10:00 AM',
        'title': 'Bãi Sao',
        'description': 'Tắm biển bãi cát trắng.',
        'icon': 'beach_access',
      };

      final item = ItineraryItem.fromJson(json);
      expect(item.location, null);
      expect(item.estimatedCost, null);
      expect(item.tips, null);
      expect(item.details, null);
    });
  });
}
