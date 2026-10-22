import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  const HomePage({super.key, required this.repository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(item.title),
                subtitle: Text('${item.price} บาท'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    context.read<CartModel>().add(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // แก้ไขปุ่ม FloatingActionButton ตรงนี้ให้เป็น Modal Bottom Sheet
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF3B3B3F), // สีพื้นหลังเทาเข้ม
            isScrollControlled: true, 
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'นี่คือตัวอย่างประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง หลากหลายสไตล์ เลือกไปปรับใช้ได้เลยครับ!\n\n'
                        '**แนวสดใส เป็นกันเอง (ยอดฮิต)**\n'
                        '* "สวัสดีค่า/ครับคุณลูกค้า ยินดีต้อนรับสู่ร้านเราน้า มีสินค้าชิ้นไหนให้ช่วยดูเป็นพิเศษไหมเอ่ย 😊"\n'
                        '* "สวัสดีวันนี้นะคะ/ครับ สนใจสินค้าตัวไหนสอบถามได้เลยน้า พ่อค้า/แม่ค้าใจดีมากกกกการันตี 😆"\n'
                        '* "ทักมาแบบนี้ ดีใจจังเลยค่ะ/ครับ มีอะไรให้แอดมินช่วยแนะนำไหมเอ่ย สอบถามก่อนได้น้าไม่ซื้อไม่เป็นไรค่า"\n\n'
                        '**แนวน่ารัก เป็นกันเองเหมือนเพื่อน**\n'
                        '* "ฮัลโหลลลคุณลูกค้า มีของในใจอยู่รึเปล่าเอ่ย หรืออยากให้เค้าแนะนำรุ่นไหนบอกได้เลยน้า"\n'
                        '* "สวัสดีค่า/ครับ แวะมาดูของก่อนได้เลยน้า มีโปรเด็ดๆ เพียบเลยตอนนี้ เล็งตัวไหนไว้ทักมาได้ตลอดเลยนะค้า"\n'
                        '* "สวัสดีค่า/ครับคุณลูกค้า วันนี้สนใจรับน้องตัวไหนกลับบ้านดีน้า ถามได้เลยน้าาา"\n\n'
                        '**แนวสั้นๆ ง่ายๆ แต่เป็นมิตร**\n'
                        '* "สวัสดีค่า/ครับคุณลูกค้า สอบถามข้อมูลสินค้าเพิ่มเติม ทักมาได้เลยน้า ยินดีให้บริการค่ะ 🙏✨"\n'
                        '* "สวัสดีค่ะ/ครับผม มีอะไรให้แอดมินช่วยดูแล พิมพ์ทิ้งไว้ได้เลยน้า เดี๋ยวรีบตอบกลับค่า!"\n'
                        '* "ยินดีต้อนรับค่า/ครับ สนใจสินค้าชิ้นไหนสอบถามได้เลยน้า แม่ค้าพร้อมสแตนด์บายค่า 🙋‍♀️"\n\n'
                        '**ทริคเพิ่มเติม:**\n'
                        '* อย่าลืมใส่ **Emoji** น่ารักๆ เช่น 😊, 🛒, ✨, น้า, ค่า, ครับ เพื่อเพิ่มความรู้สึกเป็นกันเอง\n'
                        '* ถ้าทราบชื่อลูกค้า สามารถเรียกชื่อเล่นลูกค้าด้วยจะยิ่งสนิทกันมากขึ้นครับ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20), // เพิ่มพื้นที่ว่างด้านล่าง
                    ],
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: const Color(0xFFE5D9F2), // สีปุ่มม่วงอ่อน
        child: const Icon(Icons.chat, color: Colors.deepPurple), // ไอคอนแชท
      ),
    );
  }
}