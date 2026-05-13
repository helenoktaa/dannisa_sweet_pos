import 'package:dannisa_sweet_pos/core/constants/api_constants.dart';
import 'package:dannisa_sweet_pos/core/services/dio_client.dart';
import 'package:dannisa_sweet_pos/features/dashboard/data/models/product_model.dart';
import 'package:dannisa_sweet_pos/features/dashboard/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await DioClient.instance.get(ApiConstants.produk);

    // Backend response: { "data": [ {...}, {...} ], "success": true }
    final List<dynamic> data = response.data['data'];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final response = await DioClient.instance.get(
      '${ApiConstants.produk}/$id',
    );
    return ProductModel.fromJson(response.data['data']);
  }
}