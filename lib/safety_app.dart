import 'package:flutter/material.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    //每个项目最外层，都必须要有MaterialApp

    return MaterialApp(
      title: 'Campus Safety App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
         useMaterial3: true,
         appBarTheme: AppBarTheme(
    backgroundColor: Colors.purple, // 全局 AppBar 颜色
    foregroundColor: Colors.white,  // 标题 & 图标颜色
  ),

  

      ),
      
      home: MyHome(),
   // 通过首页home 指定首页
    );//MaterialApp
   }
  }

  class MyHome extends StatelessWidget{
  const MyHome({super.key});

    @override
    Widget build(BuildContext context) {
      //in flutter, every widget is a class

      return DefaultTabController(length:3 ,child: Scaffold(    //actually is ：new Scaffold， but can ignore（more simple）
        appBar: AppBar(
          title: Text('Campus Safety App'),
           centerTitle:true,

           //右侧行为按钮
           actions:<Widget>[
             IconButton(
               icon: Icon(Icons.search),
               onPressed: () {

               }
             ),     
           ]
        ),


       drawer:Drawer(
        child:ListView(
          padding:EdgeInsets.all(0),
          children:<Widget>[

          UserAccountsDrawerHeader(
            accountName:Text( 'meixue'),
            accountEmail: Text( 'meixue@gmail.com'),
            currentAccountPicture: CircleAvatar(backgroundImage:NetworkImage
            ('https://tse1.mm.bing.net/th/id/OIP.eRNDFzrdimIPhnG5humG_gHaLH?rs=1&pid=ImgDetMain&o=7&rm=3'),),   //头像是karina的网图
            
            //decoration use for decorate current widget keke
            decoration:BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              image:DecorationImage(
                fit:BoxFit.cover,
                image:NetworkImage(
                  'https://img.uhdpaper.com/wallpaper/karina-aespa-armageddon-467@0@j'),
               opacity: 0.8,
            ),
            ),
          ), //(user info at the top section

          ListTile(
       //   leading:Icon(Icons.home),
            title:Text('News and Updates'),trailing:Icon(Icons.upcoming),
          ),

          ListTile(
       //   leading:Icon(Icons.settings),
            title:Text('Settings'),
            trailing:Icon(Icons.settings)
          ),

          ListTile(
      //    leading:Icon(Icons.info),
            title:Text('About'),
            trailing:Icon(Icons.info)
          ),  

          Divider(color:Colors.black),
           
            ListTile(
      //    leading:Icon(Icons.info),
            title:Text('Delete Account'),
            trailing:Icon(Icons.exit_to_app)
          ),  


        ],),
        
        ),


        // 主体内容 = TabBarView
        body: TabBarView(
          children: <Widget>[
            //new file:TOdo for 3 bottom bar view
            Center(child: Text("🏠 Home Page")),
            Center(child: Text("📢 Reporting Page")),
            Center(child: Text("🛠 Services Page")),
          ],
        ),


      //bottom section punya 3 icons
       bottomNavigationBar: Container(

        //decorate current widget(container)
        decoration:BoxDecoration(color:Colors.deepPurple),height: 50,

        child:TabBar(
          labelStyle:TextStyle(height:0,fontSize: 10,color:Colors.white),
          tabs: <Widget>[
         Tab(icon:Icon(Icons.home),text:'Home',),
         Tab(icon:Icon(Icons.report),text:'Reporting',),
         Tab(icon:Icon(Icons.delivery_dining),text:'Services',),
       ],
       )
       ),
      ),
       );


    }
  }


