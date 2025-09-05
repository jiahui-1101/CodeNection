import 'package:flutter/material.dart';

class NewsCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onTap; //tap on news card to redirect to news detail page

  const NewsCard({super.key, required this.imageUrl, required this.title,this.onTap,});

  @override
  Widget build(BuildContext context) {
    
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(20), 
      
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),

        //  use Align to wrap child,让 child always at bottom center
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    )
    );
  }
}
