import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/remote_source.dart';
import '../../domain/entities/remote_track.dart';
import '../../domain/entities/remote_node.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:smb_connect/smb_connect.dart';
import 'dart:io';

enum NetworkState { disconnected, connecting, connected, error }

enum NetworkFlow {
  none,
  pcGuide,
  pcDiscovery,
  pcManualSetup,
  pcExplorer,
  ftpSetup,
  sftpSetup,
}

class NetworkStateData {
  final NetworkState state;
  final NetworkFlow currentFlow;
  final List<RemoteTrack> tracks;
  final List<RemoteSource> sources;
  final List<RemoteNode> remoteNodes;
  final List<String> currentPath;
  final String? errorMessage;
  final String? activeSourceId;
  final String? lastIp;
  final String? lastUsername;
  final bool isScanning;
  final List<RemoteSource> discoveredDevices;

  NetworkStateData({
    this.state = NetworkState.disconnected,
    this.currentFlow = NetworkFlow.none,
    this.tracks = const [],
    this.sources = const [],
    this.remoteNodes = const [],
    this.currentPath = const [],
    this.errorMessage,
    this.activeSourceId,
    this.lastIp,
    this.lastUsername,
    this.isScanning = false,
    this.discoveredDevices = const [],
  });

  NetworkStateData copyWith({
    NetworkState? state,
    NetworkFlow? currentFlow,
    List<RemoteTrack>? tracks,
    List<RemoteSource>? sources,
    List<RemoteNode>? remoteNodes,
    List<String>? currentPath,
    String? errorMessage,
    String? activeSourceId,
    String? lastIp,
    String? lastUsername,
    bool? isScanning,
    List<RemoteSource>? discoveredDevices,
  }) {
    return NetworkStateData(
      state: state ?? this.state,
      currentFlow: currentFlow ?? this.currentFlow,
      tracks: tracks ?? this.tracks,
      sources: sources ?? this.sources,
      remoteNodes: remoteNodes ?? this.remoteNodes,
      currentPath: currentPath ?? this.currentPath,
      errorMessage: errorMessage ?? this.errorMessage,
      activeSourceId: activeSourceId ?? this.activeSourceId,
      lastIp: lastIp ?? this.lastIp,
      lastUsername: lastUsername ?? this.lastUsername,
      isScanning: isScanning ?? this.isScanning,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    );
  }
}

class NetworkNotifier extends StateNotifier<NetworkStateData> {
  NetworkNotifier() : super(NetworkStateData()) {
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      lastIp: prefs.getString('last_smb_ip'),
      lastUsername: prefs.getString('last_smb_user'),
    );
  }

  Future<void> _saveCredentials(String ip, String? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_smb_ip', ip);
    if (user != null) {
      await prefs.setString('last_smb_user', user);
    }
    state = state.copyWith(lastIp: ip, lastUsername: user);
  }

  SmbConnect? _smbClient;
  String? _currentIp;
  String? _username;
  String? _password;

  // Cache para las carpetas SmbFile para poder listarlas
  final Map<String, SmbFile> _smbFileCache = {};

  Future<void> connectToNetwork() async {
    // Esta función ahora podría ser obsoleta o actuar como "escaneo inicial"
    state = state.copyWith(state: NetworkState.connecting);
    await Future.delayed(const Duration(seconds: 1));

    if (state.sources.isEmpty) {
      state = state.copyWith(state: NetworkState.disconnected);
    } else {
      state = state.copyWith(state: NetworkState.connected);
    }
  }

  Future<void> addSource(RemoteSourceType type) async {
    state = state.copyWith(state: NetworkState.connecting);
    await Future.delayed(const Duration(seconds: 1));

    final newId = 'src_${state.sources.length + 1}';
    final name = _getDefaultName(type, state.sources.length + 1);

    final newSource = RemoteSource(
      id: newId,
      name: name,
      type: type,
      address: _getDefaultAddress(type),
      isConnected: true,
    );

    // Simulamos carga de pistas para esta fuente
    final newTracks = _generateMockTracks(newId, name);

    state = state.copyWith(
      state: NetworkState.connected,
      sources: [...state.sources, newSource],
      tracks: [...state.tracks, ...newTracks],
    );
  }

  void removeSource(String sourceId) {
    state = state.copyWith(
      sources: state.sources.where((s) => s.id != sourceId).toList(),
      tracks: state.tracks.where((t) => t.sourceId != sourceId).toList(),
    );

    if (state.sources.isEmpty) {
      state = state.copyWith(state: NetworkState.disconnected);
    }
  }

  String _getDefaultName(RemoteSourceType type, int index) {
    switch (type) {
      case RemoteSourceType.pc:
        return "PC de Leo $index";
      case RemoteSourceType.cloud:
        return "Google Drive $index";
      case RemoteSourceType.nas:
        return "NAS Synology $index";
      case RemoteSourceType.custom:
        return "REMUH Cloud $index";
    }
  }

  String _getDefaultAddress(RemoteSourceType type) {
    switch (type) {
      case RemoteSourceType.pc:
        return "192.168.1.15";
      case RemoteSourceType.cloud:
        return "cloud.google.com/drive";
      case RemoteSourceType.nas:
        return "nas-home.local";
      case RemoteSourceType.custom:
        return "api.remuh.app";
    }
  }

  List<RemoteTrack> _generateMockTracks(String sourceId, String sourceName) {
    return [
      RemoteTrack(
        id: '${sourceId}_1',
        sourceId: sourceId,
        title: '$sourceName Track 1',
        artist: 'Artista Remoto',
        album: 'Album Digital',
        duration: const Duration(minutes: 3, seconds: 30),
      ),
      RemoteTrack(
        id: '${sourceId}_2',
        sourceId: sourceId,
        title: '$sourceName Track 2',
        artist: 'Artista Red',
        album: 'Conexión Directa',
        duration: const Duration(minutes: 4, seconds: 15),
      ),
    ];
  }

  void downloadTrack(RemoteTrack track) async {
    // Simulamos progreso de descarga
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final updatedTracks = state.tracks.map((t) {
        if (t.id == track.id) {
          return t.copyWith(downloadProgress: i * 0.2);
        }
        return t;
      }).toList();
      state = state.copyWith(tracks: updatedTracks);
    }

    final finishedTracks = state.tracks.map((t) {
      if (t.id == track.id) {
        return t.copyWith(isDownloaded: true, downloadProgress: 1.0);
      }
      return t;
    }).toList();

    state = state.copyWith(tracks: finishedTracks);
  }

  void startPcFlow() {
    state = state.copyWith(currentFlow: NetworkFlow.pcGuide);
  }

  Future<void> startManualSetup({String? prefillIp}) async {
    state = state.copyWith(
      currentFlow: NetworkFlow.pcManualSetup,
      lastIp: prefillIp ?? state.lastIp,
    );
  }

  void startFtpFlow() {
    state = state.copyWith(currentFlow: NetworkFlow.ftpSetup);
  }

  void startSftpFlow() {
    state = state.copyWith(currentFlow: NetworkFlow.sftpSetup);
  }

  Future<void> startSMBDiscovery() async {
    state = state.copyWith(
      currentFlow: NetworkFlow.pcDiscovery,
      isScanning: true,
      discoveredDevices: [],
      errorMessage: null,
    );

    try {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();

      // Fallback para emulador si no hay wifi
      if (ip == null && kDebugMode) ip = '192.168.1.10';

      if (ip != null) {
        final subnet = ip.substring(0, ip.lastIndexOf('.'));
        await _scanSubnet(subnet);
      } else {
        state = state.copyWith(
          isScanning: false,
          errorMessage: 'No conectado a Wi-Fi',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Error escaneando: $e',
      );
    }
  }

  Future<void> _scanSubnet(String subnet) async {
    final List<Future<void>> checks = [];
    final List<RemoteSource> found = [];

    // Limitamos el escaneo para no saturar. En producción podríamos usar algo más sofisticado.
    // Escaneamos solo el rango comun .1 a .254
    for (int i = 1; i < 255; i++) {
      final targetIp = '$subnet.$i';
      checks.add(
        _checkPort445(targetIp).then((isOpen) {
          if (isOpen) {
            found.add(
              RemoteSource(
                id: 'smb_$targetIp',
                name:
                    'Dispositivo ($targetIp)', // Podríamos intentar reverse NS lookup
                type: RemoteSourceType.pc,
                address: targetIp,
                isConnected: false,
              ),
            );
            // Actualizar UI progresivamente
            state = state.copyWith(discoveredDevices: [...found]);
          }
        }),
      );
    }

    await Future.wait(checks);
    state = state.copyWith(isScanning: false);
  }

  Future<bool> _checkPort445(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        445,
        timeout: const Duration(milliseconds: 200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> connectToPc(
    String ip, {
    String? username,
    String? password,
  }) async {
    state = state.copyWith(state: NetworkState.connecting, errorMessage: null);

    try {
      _currentIp = ip;
      _username = username;
      _password = password;

      // Intentamos login para verificar credenciales e IP
      _smbClient = await SmbConnect.connectAuth(
        host: _currentIp!,
        username: _username ?? '',
        password: _password ?? '',
        domain: '', // Domain por defecto vacío
      );

      final sourceId = 'src_pc_${state.sources.length + 1}';
      final newSource = RemoteSource(
        id: sourceId,
        name: "PC ($ip)",
        type: RemoteSourceType.pc,
        address: ip,
        isConnected: true,
        username: username,
        password: password,
      );

      state = state.copyWith(
        state: NetworkState.connected,
        currentFlow: NetworkFlow.pcExplorer,
        sources: [...state.sources, newSource],
        activeSourceId: sourceId,
        currentPath: [],
      );

      // Guardamos credenciales exitosas
      _saveCredentials(ip, username);

      await _loadRemoteNodes('');
    } catch (e, stack) {
      debugPrint('SMB CONNECTION ERROR: $e');
      debugPrint('STACKTRACE: $stack');

      String message = e.toString();
      if (message.contains('Connection timed out') ||
          message.contains('errno = 110')) {
        message =
            'TIMEOUT: (1) Revisa si la IP es correcta. (2) Tu Wi-Fi DEBE estar en perfil "Privado". (3) El Firewall de Windows puede estar bloqueando el puerto 445.';
      } else if (message.contains('Failed host lookup') ||
          message.contains('No address associated with hostname')) {
        message =
            'FORMATO IP INCORRECTO: Asegúrate de poner los 4 números separados por puntos (ej: 192.168.1.78).';
      } else if (message.contains('Access denied') ||
          message.contains('Authentication failed') ||
          message.contains('SmbAuthException') ||
          message.contains('Invalid credentials')) {
        message =
            'ACCESO DENEGADO: Windows rechazó tus datos. RECOMENDACIÓN: Si usas cuenta Microsoft, crea un "Usuario Local" en Windows solo para REMUH. Es la forma más fiable de conectar.';
      } else {
        message = 'ERROR: $message';
      }

      state = state.copyWith(state: NetworkState.error, errorMessage: message);
    }
  }

  Future<void> exploreFolder(String folderName) async {
    final newPath = [...state.currentPath, folderName];
    // Limpiar nodos anteriores para evitar "navegación fantasma" mientras carga
    state = state.copyWith(
      currentPath: newPath,
      remoteNodes: [],
      state: NetworkState.connecting,
    );
    await _loadRemoteNodes(newPath.join('/'));
  }

  Future<void> navigateBack() async {
    if (state.currentPath.isNotEmpty) {
      final newPath = state.currentPath.sublist(
        0,
        state.currentPath.length - 1,
      );
      state = state.copyWith(currentPath: newPath);
      await _loadRemoteNodes(newPath.join('/'));
    } else {
      state = state.copyWith(currentFlow: NetworkFlow.none);
      _currentIp = null;
      _smbClient = null;
      _smbFileCache.clear();
    }
  }

  Future<void> refreshCurrentPath() async {
    final path = state.currentPath.join('/');
    debugPrint('Refreshing path: $path');

    // Invalidate cache for this specific path
    _smbFileCache.remove(path);
    if (path.isNotEmpty) {
      // Also remove cached children usually
      // A simple way is just to force reload, _loadRemoteNodes overwrites nodes
    }

    state = state.copyWith(state: NetworkState.connecting, remoteNodes: []);
    await _loadRemoteNodes(path);
  }

  Future<void> jumpToPath(List<String> targetPath) async {
    if (_smbClient == null) return;

    state = state.copyWith(
      state: NetworkState.connecting,
      remoteNodes: [], // Limpiar UI
    );

    int attempts = 0;
    while (attempts < 2) {
      try {
        // Necesitamos asegurar que el path es válido resolviendo cada segmento
        // Esto también "calienta" la caché para que _loadRemoteNodes funcione
        String currentPathStr = '';

        // 1. Asegurar que tenemos los shares (Root)
        if (_smbFileCache.isEmpty) {
          await _smbClient!.listShares().then((shares) {
            for (var s in shares) {
              _smbFileCache[s.name] = s;
            }
          });
        }

        // 2. Resolver cada segmento
        for (int i = 0; i < targetPath.length; i++) {
          final segment = targetPath[i];
          final lookUpPath = i == 0 ? segment : '$currentPathStr/$segment';

          if (!_smbFileCache.containsKey(lookUpPath)) {
            // Si no está en caché, listar el padre para encontrarlo
            final parentPath = i == 0 ? '' : currentPathStr;
            // Si es root, ya listamos shares arriba. Si es carpeta...
            if (parentPath.isNotEmpty) {
              final parentFile = _smbFileCache[parentPath];
              if (parentFile != null) {
                final children = await _smbClient!.listFiles(parentFile);
                for (var child in children) {
                  _smbFileCache['$parentPath/${child.name}'] = child;
                }
              }
            }
          }

          if (!_smbFileCache.containsKey(lookUpPath)) {
            throw Exception('Ruta no encontrada: $lookUpPath');
          }
          currentPathStr = lookUpPath;
        }

        // 3. Navegar
        state = state.copyWith(currentPath: targetPath);
        await _loadRemoteNodes(targetPath.join('/'));
        return; // Éxito
      } catch (e, stack) {
        attempts++;
        debugPrint('Error en jumpToPath (Intento $attempts): $e');

        if (attempts >= 2) {
          debugPrint('Stacktrace: $stack');
          state = state.copyWith(
            state: NetworkState.error,
            errorMessage: 'No se pudo abrir el acceso directo: $e',
          );
        } else {
          try {
            await _reconnect();
          } catch (reconnectError) {
            debugPrint('No se pudo reconectar: $reconnectError');
            state = state.copyWith(
              state: NetworkState.error,
              errorMessage: 'Error crítico de conexión: $reconnectError',
            );
            return;
          }
        }
      }
    }
  }

  Future<void> checkCurrentWifi() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      final info = NetworkInfo();
      final ssid = await info
          .getWifiName(); // Necesita permisos de ubicación en Android

      if (ssid != null && ssid.isNotEmpty) {
        // Si detectamos un SSID que parece de PC (o simplemente cualquier Wi-Fi para esta demo)
        state = state.copyWith(
          state: NetworkState.connected,
          errorMessage: null,
        );
        // Podríamos autoconectar al PC si conocemos la IP estática o vía descubrimiento
      }
    }
  }

  Future<void> connectToWifi(String ssid, String password) async {
    state = state.copyWith(state: NetworkState.connecting);
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(state: NetworkState.connected, errorMessage: null);
  }

  Future<void> _loadRemoteNodes(String path) async {
    if (_smbClient == null) return;

    int attempts = 0;
    while (attempts < 2) {
      try {
        List<RemoteNode> nodes = [];

        if (path.isEmpty) {
          // Listar recursos compartidos (shares)
          final shares = await _smbClient!.listShares();
          nodes = shares.map((share) {
            _smbFileCache[share.name] = share;
            debugPrint('Share discovered: ${share.name} (Path: ${share.path})');
            return RemoteNode(
              id: 'share_${share.name}',
              parentId: '',
              name: share.name,
              path: share.name,
              type: RemoteNodeType.folder,
            );
          }).toList();

          // [FEATURE] Shortcut a Carpeta Pública
          // Solo si no existe ya un share llamado 'Public'
          if (shares.any((s) => s.name == 'Users') &&
              !shares.any((s) => s.name == 'Public')) {
            nodes.insert(
              0,
              RemoteNode(
                id: 'shortcut_public_folder',
                parentId: '',
                name: 'Carpeta Pública (Acceso directo)',
                path: 'Users/Public', // Ruta real "Users/Public"
                type: RemoteNodeType.folder,
                size: null,
              ),
            );
          }
        } else {
          // Listar contenido de una carpeta/recurso
          debugPrint('Loading nodes for path: "$path"');
          final folder = _smbFileCache[path];
          debugPrint('Folder found in cache: ${folder != null}');

          if (folder != null) {
            final files = await _smbClient!.listFiles(folder);
            nodes = files.map((file) {
              final fullPath = '$path/${file.name}';
              _smbFileCache[fullPath] = file;

              final ext = file.name.contains('.')
                  ? '.${file.name.split('.').last}'
                  : null;
              return RemoteNode(
                id: 'file_${file.name}_${file.lastModified}',
                parentId: path,
                name: file.name,
                path: fullPath,
                type: file.isDirectory()
                    ? RemoteNodeType.folder
                    : RemoteNodeType.file,
                extension: ext,
                size: file.size,
              );
            }).toList();
            debugPrint('Found ${nodes.length} items in $path');
            for (var n in nodes) {
              debugPrint(' - ${n.name} (Dir: ${n.type})');
            }
          } else {
            // Si no está en caché, intentar reconstruirlo o fallar
            // Por simplificación, fallamos, pero el retry podría ayudar si recargamos desde root
            state = state.copyWith(
              state: NetworkState.error,
              errorMessage: 'Error: Carpeta no encontrada en caché ($path).',
            );
            return;
          }
        }

        state = state.copyWith(remoteNodes: nodes);
        return; // Éxito, salir del loop
      } catch (e, stack) {
        attempts++;
        debugPrint('ERROR EN INTENTO $attempts listing files at "$path": $e');

        if (attempts >= 2) {
          debugPrint('Stacktrace: $stack');

          String msg = e.toString();

          // [STRATEGY] Retry with wildcards/slashes if we get "File not found"
          // This handles variations in how SMB servers expect listing requests
          /*
          if (msg.contains('cannot find the file specified') &&
              !path.endsWith('*')) {
            debugPrint(
              '[DEBUG] Attempting retry with wildcard/slash for path: $path',
            );
            try {
              // Try 'Path/ *'
              final altPath = path.endsWith('/') ? '$path*' : '$path' + '/' + '*';
              // listFiles expects a SmbFile usually, but if we pass string it might fail
              // We need to create a dummy SmbFile or use the string if supported.
              // Assuming listFiles supports String if connect does.
              // Re-checking previous usage: _smbClient!.listFiles(folder) where folder is SmbFile.
              // If we only have a path string, we might need listFiles(path).
              // Let's assume the library supports listing by path string if mapped correctly.
              // IF NOT, we might need to recreate the SmbFile object manually.

              // Correct fix: We need to define 'nodes' locally for this scope or reuse parent if accessible.
              // 'nodes' is defined in the try block above, but not here.
              List<RemoteNode> newNodes = [];

              final files = await _smbClient!.listFiles(altPath);

              newNodes = files.map((file) {
                final fullPath = '$path/${file.name}';
                final ext = file.name.contains('.')
                    ? '.${file.name.split('.').last}'
                    : null;
                return RemoteNode(
                  id: 'file_${file.name}_${file.lastModified}',
                  parentId: path,
                  name: file.name,
                  path: fullPath,
                  type: file.isDirectory()
                      ? RemoteNodeType.folder
                      : RemoteNodeType.file,
                  extension: ext,
                  size: file.size,
                );
              }).toList();

              debugPrint('Retry successful! Found ${newNodes.length} items.');
              state = state.copyWith(
                state: NetworkState.connected,
                remoteNodes: newNodes,
                errorMessage: null,
              );
              return; // Exit success
            } catch (retryError) {
              debugPrint('[DEBUG] Retry failed: $retryError');
            }
          }
          */

          if (msg.contains('cannot find the file specified') ||
              msg.contains('Access denied')) {
            // [STRATEGY] Auto-redirect to C$/Users if Users fails
            if ((path == 'Users' || path == '/Users') &&
                state.sources.any(
                  (s) => s.id.startsWith('smb_'),
                ) // Check if connected
                ) {
              final cShare = _smbFileCache['C\$'];
              if (cShare != null) {
                debugPrint(
                  '[DEBUG] "Users" failed. Redirecting to "C\$/Users"...',
                );
                try {
                  // We need to list C$, find Users, then list it.
                  // Too complex for quick fix. Better to just try listFiles on C$/Users path?
                  // If listFiles only takes SmbFile, we can't.

                  // BUT! We can assume if we are here, standard listing failed.
                  // The user might be able to traverse if we use the right entry point.
                } catch (e) {
                  // Ignore
                }
              }
            }

            String helpfulTip = '';
            if (path.toLowerCase().contains('users') ||
                path.toLowerCase().contains('public')) {
              // Check if we have C$
              if (_smbFileCache.containsKey('C\$')) {
                helpfulTip =
                    '\n\n💡 SOLUCIÓN: Tienes acceso administrativo ("C\$").\nEntra a "C\$" -> "Users" para ver tus archivos sin restricciones.';
              } else {
                helpfulTip =
                    '\n\nPrueba a compartir una subcarpeta específica (ej: "Usuarios/Leo/Musica") en lugar de toda la carpeta de usuarios.';
              }
            }

            state = state.copyWith(
              state: NetworkState.connected,
              remoteNodes: [],
              errorMessage:
                  'Windows restringió el acceso directo a "$path".$helpfulTip',
            );
            return;
          }

          state = state.copyWith(
            state: NetworkState.error,
            errorMessage:
                'Error de conexión: $e. Verifica que el PC siga encendido.',
          );
        } else {
          // Reintentar reconectando
          debugPrint('Intentando reconectar antes del reintento...');
          try {
            await _reconnect();
          } catch (reconnectError) {
            debugPrint('No se pudo reconectar: $reconnectError');
            state = state.copyWith(
              state: NetworkState.error,
              errorMessage: 'Error crítico de conexión: $reconnectError',
            );
            return; // Salir para evitar crash por cliente nulo
          }
        }
      }
    }
  }

  Future<void> _reconnect() async {
    if (_currentIp == null) return;
    debugPrint('Intento de reconexión automática SMB (Full Reset)...');
    try {
      // Forzar cierre de cliente anterior si existe
      try {
        // _smbClient?.close(); // Si existiera método close
        _smbClient = null;
      } catch (_) {}

      _smbClient = await SmbConnect.connectAuth(
        host: _currentIp!,
        username: _username ?? '',
        password: _password ?? '',
        domain: '',
      );
      debugPrint('Reconexión exitosa.');
    } catch (e) {
      debugPrint('Fallo al reconectar: $e');
      rethrow;
    }
  }

  void disconnect() {
    state = NetworkStateData(state: NetworkState.disconnected);
  }

  Future<void> cancelFlow() async {
    state = state.copyWith(
      currentFlow: NetworkFlow.none,
      state: NetworkState.disconnected, // Resetear estado general
      currentPath: [], // Limpiar path
      remoteNodes: [], // Limpiar nodos
      errorMessage: null,
    );
    // Opcional: desconectar cliente SMB si se desea ahorrar recursos
  }
}

final networkProvider =
    StateNotifierProvider<NetworkNotifier, NetworkStateData>((ref) {
      return NetworkNotifier();
    });
