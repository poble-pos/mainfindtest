import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nsd/nsd.dart';

 const String SERVICE_TYPE = '_http._tcp';
   const String SERVICE_NAME = 'main-pos';
  
  Discovery? _discovery;
  Registration? _registration;
Future<void> advertiseMainPOS() async {
  final Map<String, Uint8List?> txtRecords = {
        'role': Uint8List.fromList('main'.codeUnits),
      };
      
  final registration = await register(
        Service(
          name: SERVICE_NAME,
          type: SERVICE_TYPE,
          port: 8090,
          txt: txtRecords
        )
      );
      _registration = registration;
      
    
      
      
      return ;
    } 

Future<void> stopAdvertisement() async {
  if (_registration != null) {
    await unregister(_registration!);
    _registration = null;
  }
}

Future<String?> findMainPOS() async {
  final discovery = await startDiscovery(
    SERVICE_TYPE,
    ipLookupType: IpLookupType.v4,
  );

  final completer = Completer<String?>();

  discovery.addServiceListener((Service service, ServiceStatus status) async {
    if (status == ServiceStatus.found && service.name == SERVICE_NAME) {
      final addresses = service.addresses;
      if (addresses != null && addresses.isNotEmpty) {
        final ipv4 = addresses.firstWhere(
          (addr) => addr.type == InternetAddressType.IPv4,
          orElse: () => InternetAddress(''),
        );
        if (ipv4.address.isNotEmpty) {
          completer.complete(ipv4.address);
        }
      }
    }
  });

  Future.delayed(Duration(seconds: 3), () {
    if (!completer.isCompleted) {
      completer.complete(null); // graceful fail
    }
  });

  return completer.future;
}

Future<List<String>> findMainPOSList({Duration timeout = const Duration(seconds: 5)}) async {
  final discovery = await startDiscovery(
    SERVICE_TYPE,
    ipLookupType: IpLookupType.v4,
  );

  final Set<String> ipSet = {};
  final completer = Completer<List<String>>();

  discovery.addServiceListener((Service service, ServiceStatus status) async {
    print('status: $status  service.name ${service.name}');
    if (status == ServiceStatus.found && service.name!.startsWith(SERVICE_NAME,0)) //multiple same service names like main-pos, main-pos (2),main-pos (3)
    {
      final addresses = service.addresses;
      if (addresses != null && addresses.isNotEmpty) {
        for (var addr in addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            ipSet.add(addr.address);
          }
        }
      }
    } else if (status == ServiceStatus.lost && service.name == SERVICE_NAME) {
      // Use ServiceStatus.lost to handle when a service is removed
      final addresses = service.addresses;
      if (addresses != null && addresses.isNotEmpty) {
        for (var addr in addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            ipSet.remove(addr.address);
          }
        }
      }
    }
  });

  // Timeout after the given duration
  Future.delayed(timeout, () {
    completer.complete(ipSet.toList());
  });

  return completer.future;
}
