import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color, Colors;

import 'l10n/app_localizations.dart';

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.color,
    this.colors = const [],
    this.logoVersion,
    this.createdAt,
  });

  static const maxBrandColors = 3;

  final String id;
  final String name;
  final String ownerUid;

  /// Main brand colour (the first of [colors]); used for cards without a design.
  final int color;

  /// 1 to 3 brand colours chosen during sign-up. Empty until the owner picks them.
  final List<int> colors;

  final DateTime? createdAt;

  /// Colours to start new cards from.
  List<int> get brandColors => colors.isEmpty ? [color] : colors;

  /// Bumped on every logo upload; null when the business has no logo.
  final int? logoVersion;

  LogoRef? get logo => logoVersion == null ? null : LogoRef(businessId: id, version: logoVersion!);

  factory Business.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Business(
      id: doc.id,
      name: d['name'] as String? ?? '',
      ownerUid: d['ownerUid'] as String? ?? '',
      color: d['color'] as int? ?? 0xFFFF5A3C,
      colors: [
        for (final c in d['colors'] as List? ?? const [])
          if (c is int) c,
      ],
      logoVersion: d['logoVersion'] as int?,
      createdAt: _date(d['createdAt']),
    );
  }
}

/// Points at a business logo stored in `logos/{businessId}`; the version busts caches.
class LogoRef {
  const LogoRef({required this.businessId, required this.version});

  final String businessId;
  final int version;

  @override
  bool operator ==(Object other) => other is LogoRef && other.businessId == businessId && other.version == version;

  @override
  int get hashCode => Object.hash(businessId, version);
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

  /// A card in the business's brand colours: the first as background, the second as
  /// gradient end, the third for the stamps.
  factory CardDesign.fromBrand(List<int> colors) => CardDesign(
    background: colors.first,
    background2: colors.length > 1 ? colors[1] : null,
    style: colors.length > 1 ? CardStyle.gradient : CardStyle.solid,
    stampColor: colors.length > 2 ? colors[2] : 0xFFFFFFFF,
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

  CardDesign designFor(Business business) => design ?? CardDesign.fromBrand(business.brandColors);

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
    this.ownerUid = '',
    required this.stamps,
    required this.rewardsAvailable,
    required this.totalStamps,
    required this.totalRedeemed,
    this.lastStampAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientUid;
  final String businessId;
  final String programId;
  final String ownerUid;
  final int stamps;
  final int rewardsAvailable;
  final int totalStamps;
  final int totalRedeemed;
  final DateTime? lastStampAt;

  /// When the client joined (first tap).
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The client's most recent visit: their last stamp, or joining.
  DateTime? get lastVisit => lastStampAt ?? createdAt ?? updatedAt;

  /// Stamps roll over on the next tap; mirror that here in case the business
  /// lowered `stampsRequired` in the meantime.
  ({int stamps, int rewards}) progressFor(int stampsRequired) =>
      (stamps: stamps % stampsRequired, rewards: rewardsAvailable + stamps ~/ stampsRequired);

  factory LoyaltyCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return LoyaltyCard(
      id: doc.id,
      clientUid: d['clientUid'] as String,
      businessId: d['businessId'] as String,
      programId: d['programId'] as String,
      ownerUid: d['ownerUid'] as String? ?? '',
      stamps: d['stamps'] as int? ?? 0,
      rewardsAvailable: d['rewardsAvailable'] as int? ?? 0,
      totalStamps: d['totalStamps'] as int? ?? 0,
      totalRedeemed: d['totalRedeemed'] as int? ?? 0,
      lastStampAt: _date(d['lastStampAt']),
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }
}

/// A stamp or a redemption, for the business activity feed and insights.
class ActivityItem {
  const ActivityItem({
    required this.isRedemption,
    required this.programId,
    required this.at,
    this.rewardTitle,
    this.cardId = '',
    this.clientUid = '',
  });

  final bool isRedemption;
  final String programId;
  final DateTime at;
  final String? rewardTitle;
  final String cardId;
  final String clientUid;

  factory ActivityItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {required bool isRedemption}) {
    final d = doc.data()!;
    return ActivityItem(
      isRedemption: isRedemption,
      programId: d['programId'] as String,
      at: _date(d['createdAt']) ?? DateTime.now(),
      rewardTitle: d['rewardTitle'] as String?,
      cardId: d['cardId'] as String? ?? '',
      clientUid: d['clientUid'] as String? ?? '',
    );
  }
}

/// Who a follow-up message is shown to. Matched on the client's own device
/// against their card ([audiencesFor]), so the shop never learns who saw it.
/// The names are stored in Firestore: never rename one.
enum Audience { all, newcomers, almost, reward, slipping, lost }

extension AudienceText on Audience {
  String label(L10n l) => switch (this) {
    Audience.all => l.audienceAll,
    Audience.newcomers => l.audienceNew,
    Audience.almost => l.audienceAlmost,
    Audience.reward => l.audienceReward,
    Audience.slipping => l.audienceSlipping,
    Audience.lost => l.audienceLost,
  };

  String description(L10n l) => switch (this) {
    Audience.all => l.audienceAllDesc,
    Audience.newcomers => l.audienceNewDesc,
    Audience.almost => l.audienceAlmostDesc,
    Audience.reward => l.audienceRewardDesc,
    Audience.slipping => l.audienceSlippingDesc,
    Audience.lost => l.audienceLostDesc,
  };
}

/// The groups a card's holder belongs to right now. Shared by the client app
/// (which message to show) and the business app (client lists, reach).
Set<Audience> audiencesFor(LoyaltyCard card, Program program, DateTime now) {
  final progress = card.progressFor(program.stampsRequired);
  final toGo = program.stampsRequired - progress.stamps;
  final last = card.lastVisit;
  final daysAway = last == null ? 0 : now.difference(last).inDays;
  final joined = card.createdAt;
  return {
    Audience.all,
    if (joined != null && now.difference(joined).inDays < 14) Audience.newcomers,
    if (progress.rewards > 0) Audience.reward,
    if (progress.rewards == 0 && toGo <= 2 && program.stampsRequired > 2) Audience.almost,
    if (daysAway >= 30 && daysAway < 90) Audience.slipping,
    if (daysAway >= 90) Audience.lost,
  };
}

/// A short in-app message from a shop to (a group of) its card holders, shown
/// on their card in Loyi. No push, no email, no personal data.
class ShopMessage {
  const ShopMessage({
    required this.id,
    required this.businessId,
    required this.ownerUid,
    required this.title,
    required this.body,
    required this.audience,
    required this.active,
    required this.endsAt,
    this.programId,
    this.createdAt,
  });

  static const maxTitle = 60;
  static const maxBody = 240;

  final String id;
  final String businessId;
  final String ownerUid;

  /// Null: every card of the shop.
  final String? programId;
  final String title;
  final String body;
  final Audience audience;

  /// Paused messages stay in the list but aren't shown.
  final bool active;
  final DateTime endsAt;
  final DateTime? createdAt;

  bool liveAt(DateTime now) => active && endsAt.isAfter(now);

  /// Whether the holder of [card] should see this message now.
  bool showsFor(LoyaltyCard card, Program program, DateTime now) =>
      liveAt(now) &&
      card.businessId == businessId &&
      (programId == null || programId == card.programId) &&
      audiencesFor(card, program, now).contains(audience);

  factory ShopMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ShopMessage(
      id: doc.id,
      businessId: d['businessId'] as String,
      ownerUid: d['ownerUid'] as String,
      programId: d['programId'] as String?,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      audience: Audience.values.asNameMap()[d['audience']] ?? Audience.all,
      active: d['active'] as bool? ?? false,
      endsAt: _date(d['endsAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: _date(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'ownerUid': ownerUid,
    'programId': programId,
    'title': title,
    'body': body,
    'audience': audience.name,
    'active': active,
    'endsAt': Timestamp.fromDate(endsAt),
  };
}

/// A business owner's Loyi subscription (`subscriptions/{ownerUid}`), written
/// by the billing webhook. Tags only work while it hasn't expired.
class Subscription {
  const Subscription({required this.expiresAt, this.willRenew = true, this.billingIssue = false, this.store});

  factory Subscription.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Subscription(
      expiresAt: _date(d['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      willRenew: d['willRenew'] as bool? ?? true,
      billingIssue: d['billingIssue'] as bool? ?? false,
      store: d['store'] as String?,
    );
  }

  final DateTime expiresAt;
  final bool willRenew;
  final bool billingIssue;

  /// `app_store`, `play_store`, `stripe` (web), or null for a manual grant.
  final String? store;

  bool get isActive => expiresAt.isAfter(DateTime.now());
}
