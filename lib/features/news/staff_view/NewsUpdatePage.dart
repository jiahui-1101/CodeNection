import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsUpdatePage extends StatefulWidget {
  const NewsUpdatePage({super.key});

  @override
  State<NewsUpdatePage> createState() => _NewsUpdatePageState();
}

class _NewsUpdatePageState extends State<NewsUpdatePage> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _newsLimit = 10;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  String? _editingDocId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _dateController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreNews();
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('pinned', descending: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_newsLimit)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading more news: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showAddNewsDialog({Map<String, dynamic>? newsData, String? docId}) {
    final isEditing = newsData != null;
    if (isEditing) {
      _titleController.text = newsData['title'] ?? '';
      _dateController.text = newsData['date'] ?? '';
      _contentController.text = newsData['content'] ?? '';
      _imageController.text = newsData['image'] ?? '';
      _editingDocId = docId;
    } else {
      _clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? "Edit News" : "Add News Update",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Content",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _imageController,
                  decoration: InputDecoration(
                    labelText: "Image URL (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _clearControllers();
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.isEmpty ||
                            _dateController.text.isEmpty ||
                            _contentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (isEditing) {
                          await FirebaseFirestore.instance
                              .collection('news')
                              .doc(_editingDocId)
                              .update({
                            'title': _titleController.text,
                            'date': _dateController.text,
                            'content': _contentController.text,
                            'image': _imageController.text,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await FirebaseFirestore.instance
                              .collection('news')
                              .add({
                            'title': _titleController.text,
                            'date': _dateController.text,
                            'content': _contentController.text,
                            'image': _imageController.text,
                            'pinned': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }

                        _clearControllers();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing
                                ? 'News updated successfully!'
                                : 'News added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(isEditing ? "Update News" : "Add News"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearControllers() {
    _titleController.clear();
    _dateController.clear();
    _contentController.clear();
    _imageController.clear();
    _editingDocId = null;
  }

  Future<void> _deleteNews(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('news').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('News deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete news'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePinStatus(String docId, bool currentlyPinned) async {
    try {
      await FirebaseFirestore.instance.collection('news').doc(docId).update({
        'pinned': !currentlyPinned,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentlyPinned
              ? 'News pinned successfully'
              : 'News unpinned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update pin status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewsDetail(Map<String, dynamic> news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(news: news),
      ),
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> news, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showNewsDetail(news),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if ((news['image'] ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: news['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.article, size: 30),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        news['date'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['content'] ?? '',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[800]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        news['pinned'] ?? false
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.orange,
                      ),
                      onPressed: () => _togglePinStatus(id, news['pinned'] ?? false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddNewsDialog(newsData: news, docId: id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNews(id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(width: 80, height: 80, child: ColoredBox(color: Colors.grey)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ColoredBox(color: Colors.grey, child: SizedBox(height: 16, width: double.infinity)),
                        SizedBox(height: 8),
                        ColoredBox(color: Colors.grey, child: SizedBox(height: 12, width: 100)),
                        SizedBox(height: 12),
                        ColoredBox(color: Colors.grey, child: SizedBox(height: 14, width: double.infinity)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Updates"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('news')
                      .orderBy('pinned', descending: true)
                      .orderBy('createdAt', descending: true)
                      .limit(_newsLimit)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerLoader();
                    }

                    final newsDocs = snapshot.data?.docs ?? [];
                    if (newsDocs.isEmpty) {
                      return const Center(child: Text('No news yet'));
                    }

                    _lastDocument = newsDocs.last;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: newsDocs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == newsDocs.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final news = newsDocs[index].data() as Map<String, dynamic>;
                        return _buildNewsItem(news, newsDocs[index].id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNewsDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Detail"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((news['image'] ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: news['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article, size: 50),
              ),
            const SizedBox(height: 16),
            Text(news['date'] ?? '', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(news['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(news['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
