import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color, Colors;

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.color,
    this.logoUrl,
    this.logoPath,
  });

  final String id;
  final String name;
  final String ownerUid;

  /// Brand colour; the default for new cards and for cards without a design.
  final int color;
  final String? logoUrl;

  /// Storage path of the current logo, so it can be replaced/removed.
  final String? logoPath;

  factory Business.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Business(
      id: doc.id,
      name: d['name'] as String? ?? '',
      ownerUid: d['ownerUid'] as String? ?? '',
      color: d['color'] as int? ?? 0xFFFF5A3C,
      logoUrl: d['logoUrl'] as String?,
      logoPath: d['logoPath'] as String?,
    );
  }
}

enum CardStyle { solid, gradient, pattern }

/// How a loyalty card looks. Kept to colours + an icon so the same design can
/// later be rendered as an Apple/Google Wallet pass.
class CardDesign {
  const CardDesign({
    required this.background,
    this.background2,
    this.style = CardStyle.gradient,
    this.stampColor = 0xFFFFFFFF,
    this.stampIcon = 'check',
  });

  final int background;

  /// Gradient end colour; derived from [background] when null.
  final int? background2;
  final CardStyle style;
  final int stampColor;

  /// Key into `stampIcons` (widgets/stamp_icons.dart).
  final String stampIcon;

  Color get backgroundColor => Color(background);
  Color get secondaryColor =>
      background2 != null ? Color(background2!) : Color.lerp(backgroundColor, Colors.black, 0.25)!;
  Color get stampFill => Color(stampColor);
  Color get textColor => readableOn(backgroundColor);

  /// On a light stamp the card colour is used for the icon, unless the card is light too.
  Color get stampIconColor => stampFill.computeLuminance() > 0.6 && backgroundColor.computeLuminance() < 0.5
      ? backgroundColor
      : readableOn(stampFill);

  CardDesign copyWith({
    int? background,
    int? Function()? background2,
    CardStyle? style,
    int? stampColor,
    String? stampIcon,
  }) => CardDesign(
    background: background ?? this.background,
    background2: background2 != null ? background2() : this.background2,
    style: style ?? this.style,
    stampColor: stampColor ?? this.stampColor,
    stampIcon: stampIcon ?? this.stampIcon,
  );

  factory CardDesign.fromMap(Map<String, dynamic> m) => CardDesign(
    background: m['background'] as int,
    background2: m['background2'] as int?,
    style: CardStyle.values.asNameMap()[m['style']] ?? CardStyle.gradient,
    stampColor: m['stampColor'] as int? ?? 0xFFFFFFFF,
    stampIcon: m['stampIcon'] as String? ?? 'check',
  );

  Map<String, dynamic> toMap() => {
    'background': background,
    'background2': background2,
    'style': style.name,
    'stampColor': stampColor,
    'stampIcon': stampIcon,
  };
}

/// Black or white, whichever reads better on [background].
Color readableOn(Color background) => background.computeLuminance() > 0.5 ? const Color(0xDD000000) : Colors.white;

class Reward {
  const Reward({required this.id, required this.title, this.active = true});

  final String id;
  final String title;
  final bool active;

  Reward copyWith({String? title, bool? active}) =>
      Reward(id: id, title: title ?? this.title, active: active ?? this.active);

  factory Reward.fromMap(Map<String, dynamic> m) =>
      Reward(id: m['id'] as String, title: m['title'] as String? ?? '', active: m['active'] as bool? ?? true);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'active': active};
}

class Program {
  const Program({
    required this.id,
    required this.businessId,
    required this.ownerUid,
    required this.name,
    required this.stampsRequired,
    required this.stampCooldownMinutes,
    required this.rewards,
    required this.active,
    this.design,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String ownerUid;
  final String name;
  final int stampsRequired;
  final int stampCooldownMinutes;
  final List<Reward> rewards;
  final bool active;

  /// Null for cards created before designs existed; see [designFor].
  final CardDesign? design;
  final DateTime? createdAt;

  CardDesign designFor(Business business) => design ?? CardDesign(background: business.color);

  List<Reward> get activeRewards => rewards.where((r) => r.active).toList();

  factory Program.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Program(
      id: doc.id,
      businessId: d['businessId'] as String,
      ownerUid: d['ownerUid'] as String,
      name: d['name'] as String? ?? '',
      stampsRequired: d['stampsRequired'] as int? ?? 10,
      stampCooldownMinutes: d['stampCooldownMinutes'] as int? ?? 0,
      rewards: [
        for (final r in (d['rewards'] as List? ?? const [])) Reward.fromMap(Map<String, dynamic>.from(r as Map)),
      ],
      active: d['active'] as bool? ?? true,
      design: d['design'] is Map ? CardDesign.fromMap(Map<String, dynamic>.from(d['design'] as Map)) : null,
      createdAt: _date(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'ownerUid': ownerUid,
    'name': name,
    'stampsRequired': stampsRequired,
    'stampCooldownMinutes': stampCooldownMinutes,
    'rewards': [for (final r in rewards) r.toMap()],
    'active': active,
    if (design != null) 'design': design!.toMap(),
  };
}

enum TagType { join, stamp }

class LoyiTag {
  const LoyiTag({
    required this.id,
    required this.programId,
    required this.type,
    required this.label,
    required this.active,
    required this.tapCount,
    this.lastTapAt,
  });

  final String id;
  final String programId;
  final TagType type;
  final String label;
  final bool active;
  final int tapCount;
  final DateTime? lastTapAt;

  factory LoyiTag.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return LoyiTag(
      id: doc.id,
      programId: d['programId'] as String,
      type: TagType.values.byName(d['type'] as String),
      label: d['label'] as String? ?? '',
      active: d['active'] as bool? ?? true,
      tapCount: d['tapCount'] as int? ?? 0,
      lastTapAt: _date(d['lastTapAt']),
    );
  }
}

class LoyaltyCard {
  const LoyaltyCard({
    required this.id,
    required this.clientUid,
    required this.businessId,
    required this.programId,
    required this.stamps,
    required this.rewardsAvailable,
    required this.totalStamps,
    required this.totalRedeemed,
    this.updatedAt,
  });

  final String id;
  final String clientUid;
  final String businessId;
  final String programId;
  final int stamps;
  final int rewardsAvailable;
  final int totalStamps;
  final int totalRedeemed;
  final DateTime? updatedAt;

  /// The server rolls stamps over on the next tap; mirror that here in case
  /// the business lowered `stampsRequired` in the meantime.
  ({int stamps, int rewards}) progressFor(int stampsRequired) =>
      (stamps: stamps % stampsRequired, rewards: rewardsAvailable + stamps ~/ stampsRequired);

  factory LoyaltyCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return LoyaltyCard(
      id: doc.id,
      clientUid: d['clientUid'] as String,
      businessId: d['businessId'] as String,
      programId: d['programId'] as String,
      stamps: d['stamps'] as int? ?? 0,
      rewardsAvailable: d['rewardsAvailable'] as int? ?? 0,
      totalStamps: d['totalStamps'] as int? ?? 0,
      totalRedeemed: d['totalRedeemed'] as int? ?? 0,
      updatedAt: _date(d['updatedAt']),
    );
  }
}

/// A stamp or a redemption, for the business activity feed.
class ActivityItem {
  const ActivityItem({required this.isRedemption, required this.programId, required this.at, this.rewardTitle});

  final bool isRedemption;
  final String programId;
  final DateTime at;
  final String? rewardTitle;

  factory ActivityItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {required bool isRedemption}) {
    final d = doc.data()!;
    return ActivityItem(
      isRedemption: isRedemption,
      programId: d['programId'] as String,
      at: _date(d['createdAt']) ?? DateTime.now(),
      rewardTitle: d['rewardTitle'] as String?,
    );
  }
}
