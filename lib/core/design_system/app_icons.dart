import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centralized icon mappings using Lucide Icons for MyDay
class AppIcons {
  AppIcons._();

  // Navigation
  static const IconData home = LucideIcons.house;
  static const IconData tasks = LucideIcons.listTodo;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData notes = LucideIcons.fileText;
  static const IconData wallet = LucideIcons.wallet;
  static const IconData feed = LucideIcons.image;
  static const IconData clock = LucideIcons.clock;
  static const IconData bell = LucideIcons.bell;
  static const IconData sparkles = LucideIcons.sparkles;
  static const IconData files = LucideIcons.fileUp;
  static const IconData trash = LucideIcons.trash2;
  static const IconData user = LucideIcons.user;
  static const IconData settings = LucideIcons.settings;
  static const IconData phone = LucideIcons.phone;
  static const IconData phoneCall = LucideIcons.phoneCall;
  static const IconData phoneIncoming = LucideIcons.phoneIncoming;
  static const IconData phoneOutgoing = LucideIcons.phoneOutgoing;
  static const IconData phoneMissed = LucideIcons.phoneMissed;
  static const IconData phoneOff = LucideIcons.phoneOff;

  // Actions
  static const IconData plus = LucideIcons.plus;
  static const IconData menu = LucideIcons.menu;
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.chevronRight;
  static const IconData check = LucideIcons.check;
  static const IconData close = LucideIcons.x;
  static const IconData search = LucideIcons.search;
  static const IconData pin = LucideIcons.pin;
  static const IconData edit = LucideIcons.pencil;
  static const IconData heart = LucideIcons.heart;
  static const IconData message = LucideIcons.messageCircle;
  static const IconData messageCircle = LucideIcons.messageCircle;
  static const IconData send = LucideIcons.send;
  static const IconData widget = LucideIcons.layoutGrid;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData share = LucideIcons.share2;
  static const IconData copy = LucideIcons.copy;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.upload;
  static const IconData logout = LucideIcons.logOut;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData reset = LucideIcons.rotateCcw;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData undo = LucideIcons.undo2;
  static const IconData redo = LucideIcons.redo2;
  static const IconData wrap = LucideIcons.wrapText;

  // Aliases for convenience
  static const IconData checkSquare = LucideIcons.squareCheck;
  static const IconData fileText = LucideIcons.fileText;
  static const IconData image = LucideIcons.image;
  static const IconData file = LucideIcons.file;
  static const IconData trash2 = LucideIcons.trash2;
  static const IconData refreshCw = LucideIcons.rotateCcw;
  static const IconData refresh = LucideIcons.rotateCcw;
  static const IconData key = LucideIcons.key;
  static const IconData camera = LucideIcons.camera;
  static const IconData money = LucideIcons.banknote;
  static const IconData x = LucideIcons.x;
  static const IconData logOut = LucideIcons.logOut;
  static const IconData arrowRightLeft = LucideIcons.arrowRightLeft;
  static const IconData info = LucideIcons.info;

  // Categories
  static const IconData food = LucideIcons.utensils;
  static const IconData groceries = LucideIcons.shoppingBag;
  static const IconData transport = LucideIcons.car;
  static const IconData fuel = LucideIcons.fuel;
  static const IconData shopping = LucideIcons.shoppingCart;
  static const IconData bills = LucideIcons.zap;
  static const IconData rent = LucideIcons.house;
  static const IconData health = LucideIcons.heart;
  static const IconData entertainment = LucideIcons.film;
  static const IconData fun = LucideIcons.star;
  static const IconData education = LucideIcons.book;
  static const IconData travel = LucideIcons.plane;
  static const IconData salary = LucideIcons.coins;
  static const IconData investment = LucideIcons.trendingUp;
  static const IconData gift = LucideIcons.gift;
  static const IconData other = LucideIcons.circleDollarSign;

  static IconData getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return food;
      case 'groceries':
        return groceries;
      case 'transport':
        return transport;
      case 'fuel':
        return fuel;
      case 'shopping':
        return shopping;
      case 'bills':
        return bills;
      case 'rent':
        return rent;
      case 'health':
        return health;
      case 'entertainment':
        return entertainment;
      case 'fun':
        return fun;
      case 'education':
        return education;
      case 'travel':
        return travel;
      case 'salary':
        return salary;
      case 'investment':
        return investment;
      case 'gift':
        return gift;
      default:
        return other;
    }
  }
}
