import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final key = prefs.getString('privateKey');

  final Ed25519HDKeyPair pair;
  if (key == null) {
    pair = await Ed25519HDKeyPair.random();
    final privateKey =
        await pair.extract().then((value) => value.bytes).then(base58encode);
    await prefs.setString('privateKey', privateKey);
    await prefs.setString('publicKey', pair.publicKey.toBase58());
  } else {
    final privateKey = base58decode(key);
    pair = await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: privateKey);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Walletu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Walletu Demu'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _solBalance = 0;

  RpcClient rpcClient = RpcClient('http://127.0.0.1:8899');

  SolanaClient client = SolanaClient(
    rpcUrl: Uri.parse('http://127.0.0.1:8899'),
    websocketUrl: Uri.parse('ws://127.0.0.1:8900'),
  );

  void _airdropSol() async {
    final prefs = await SharedPreferences.getInstance();

    print(await client.requestAirdrop(
        address: Ed25519HDPublicKey.fromBase58(prefs.getString('publicKey')!),
        lamports: 1000000000));

    BalanceResult balanceResult =
        await rpcClient.getBalance(prefs.getString('publicKey')!);

    setState(() {
      _solBalance = balanceResult.value / 1000000000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Solana Balance',
            ),
            Text(
              _solBalance.toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _airdropSol,
            tooltip: 'Aidrop Solana',
            child: const Icon(Icons.add),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: _sendSolana,
            tooltip: 'Aidrop Solana',
            child: const Icon(Icons.send),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
