import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'theme_manager.dart';
import 'package:provider/provider.dart';
import 'audio_player_widget.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeManager themeManager = await ThemeManager.loadPreferences();
  runApp(MyApp(themeManager: themeManager));
  initializeDateFormatting().then((_) => runApp(MyApp(themeManager: themeManager)));
}

class MyApp extends StatelessWidget {
  final ThemeManager themeManager;
  MyApp({required this.themeManager});

  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>(
      create: (_) => themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, theme, _) => MaterialApp(
          theme: theme.themeData,
          home: ChatPage(),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );
  List<String> _significantWords = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessage();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Collect all user messages
    List<String> userMessages = _messages
        .where((msg) => msg is types.TextMessage && msg.author.id == _user.id)
        .map((msg) => (msg as types.TextMessage).text)
        .toList();

    // Calculate weights
    List<Map<String, dynamic>> weightedMessages = _calculateWeights(userMessages);
    print(userMessages);

    // Use appropriate URL depending on the platform
    final url = (Platform.isAndroid)
        ? 'http://10.0.2.2:5000/significant-words'
        : 'http://127.0.0.1:5000/significant-words';

    // Send to backend
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text_weight_pairs': weightedMessages,
        'num_words': 7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> significantWords = List<String>.from(data['significant_words']);
      print('Significant words: $significantWords');

      // Combine significant words into a single string
      String combinedKeywords = significantWords.join(" ");
      print('Combined Keywords: $combinedKeywords');

      // Send the combined keywords to the prediction API
      await _sendKeywordToApi(combinedKeywords);
    } else {
      throw Exception('Failed to load significant words');
    }
  }

  Future<void> _sendKeywordToApi(String keywords) async {
    final predictionResponse = await http.post(
      Uri.parse('https://api.replicate.com/v1/predictions'),
      headers: {
        'Authorization': 'Bearer r8_BzCm7TjVpG05T35ULo6qaaUXOmoBiGp1g7hYK',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'version': '671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb',
        'input': {
          'prompt': keywords,
        },
      }),
    );

    if (predictionResponse.statusCode == 201) {
      final predictionData = json.decode(predictionResponse.body);
      final predictionId = predictionData['id'];
      print('Prediction created: $predictionId');

      // Check the status of the prediction
      await _checkPredictionStatus(predictionId);
    } else {
      print('Prediction response status: ${predictionResponse.statusCode}');
      print('Prediction response body: ${predictionResponse.body}');
      throw Exception('Failed to create prediction');
    }
  }

  Future<void> _checkPredictionStatus(String predictionId) async {
    while (true) {
      final statusResponse = await http.get(
        Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
        headers: {
          'Authorization': 'Bearer r8_BzCm7TjVpG05T35ULo6qaaUXOmoBiGp1g7hYK',
        },
      );

      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        final status = statusData['status'];
        if (status == 'succeeded') {
          final outputUrl = statusData['output'];
          _addMusicMessage(outputUrl);
          break;
        } else if (status == 'failed') {
          throw Exception('Prediction failed');
        } else {
          // Wait for a few seconds before checking the status again
          await Future.delayed(Duration(seconds: 5));
        }
      } else {
        throw Exception('Failed to check prediction status');
      }
    }
  }

  void _addMusicMessage(String url) {
    final musicMessage = types.CustomMessage(
      author: types.User(
        id: 'muziker_ai',
        firstName: 'Muziker',
        lastName: 'AI',
        imageUrl: 'assets/logo.png',
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      metadata: {
        'type': 'audio',
        'url': url,
      },
    );
    print(url);
    _addMessage(musicMessage);
  }

  List<Map<String, dynamic>> _calculateWeights(List<String> messages) {
    int n = messages.length;
    List<Map<String, dynamic>> weightedMessages = [];

    for (int i = 0; i < n; i++) {
      double weight = (n - i) / ((n * (n + 1)) / 2);
      weightedMessages.add({
        'text': messages[i],
        'weight': weight,
      });
    }
    print(weightedMessages);
    return weightedMessages;
  }

  void _loadInitialMessage() async {
    final random = Random();
    final response = await rootBundle.loadString('assets/messages.json');
    final List initialMessages = jsonDecode(response);
    int randomIndex = random.nextInt(initialMessages.length);
    var selectedMessage = initialMessages[randomIndex];

    var initialMessage;
    if (selectedMessage['type'] == 'text') {
      initialMessage = types.TextMessage(
        author: types.User(
          id: selectedMessage['author']['id'],
          firstName: selectedMessage['author']['firstName'],
          lastName: selectedMessage['author']['lastName'],
          imageUrl: selectedMessage['author']['imageUrl'],
        ),
        createdAt: selectedMessage['createdAt'],
        id: selectedMessage['id'],
        text: selectedMessage['text'],
        type: types.MessageType.text,
      );
    } else if (selectedMessage['type'] == 'custom' && selectedMessage['metadata']['type'] == 'audio') {
      initialMessage = types.CustomMessage(
        author: types.User(
          id: selectedMessage['author']['id'],
          firstName: selectedMessage['author']['firstName'],
          lastName: selectedMessage['author']['lastName'],
          imageUrl: selectedMessage['author']['imageUrl'],
        ),
        createdAt: selectedMessage['createdAt'],
        id: selectedMessage['id'],
        metadata: {
          'type': 'audio',
          'url': selectedMessage['metadata']['url'],
        },
      );
    }

    if (initialMessage != null) {
      _addMessage(initialMessage);
    }
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Accessing the current theme data from ThemeManager
    final themeManager = Provider.of<ThemeManager>(context);
    final chatTheme = DefaultChatTheme(
      inputBackgroundColor: themeManager.themeData.inputDecorationTheme.fillColor ?? Color(0xFF7B2CBF)!,
      backgroundColor: themeManager.themeData.scaffoldBackgroundColor,
      sentMessageBodyTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onPrimary),
      sentMessageCaptionTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onPrimary),
      sentMessageDocumentIconColor: themeManager.themeData.primaryColor,
      primaryColor: themeManager.themeData.primaryColor,
      secondaryColor: themeManager.themeData.colorScheme.secondary,
      receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
      receivedMessageCaptionTextStyle: TextStyle(color: themeManager.themeData.colorScheme.onSecondary),
      receivedMessageDocumentIconColor: themeManager.themeData.colorScheme.inverseSurface,
      inputTextColor: Colors.white,
      inputTextCursorColor: themeManager.themeData.primaryColor,
      dateDividerTextStyle: TextStyle(color: Colors.white),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Muziker')),
      body: Chat(
        messages: _messages,
        onAttachmentPressed: _handleAttachmentPressed,
        onMessageTap: _handleMessageTap,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _user,
        theme: chatTheme,
        customMessageBuilder: _buildCustomMessage,
      ),
    );
  }

  Widget _buildCustomMessage(types.CustomMessage message, {required int messageWidth}) {
    if (message.metadata?['type'] == 'audio') {
      final String url = message.metadata!['url'];
      final bool isAsset = url.startsWith('assets/');
      return AudioPlayerWidget(url: url, isAsset: isAsset);
    }
    return const SizedBox.shrink();
  }
}
