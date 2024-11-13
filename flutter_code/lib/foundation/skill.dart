import 'effect.dart';

enum SkillID {
  parry,

  metalPassive_0,
  waterPassive_0,
  woodPassive_0,
  firePassive_0,
  earthPassive_0,

  metalActive_0,
  waterActive_0,
  woodActive_0,
  fireActive_0,
  earthActive_0,

  metalPassive_1,
  waterPassive_1,
  woodPassive_1,
  firePassive_1,
  earthPassive_1,

  metalActive_1,
  waterActive_1,
  woodActive_1,
  fireActive_1,
  earthActive_1,

  metalActive_2,
  waterActive_2,
  woodActive_2,
  fireActive_2,
  earthActive_2,
}

// 技能类型
enum SkillType {
  active,
  passive,
}

// 技能目标类型
enum SkillTarget {
  selfFront,
  selfAny,

  enemyFront,
  enemyAny,
}

// 技能
class CombatSkill {
  final SkillID id;
  final String name;
  final String description;
  SkillType type;
  SkillTarget targetType;
  void Function(List<CombatSkill> skills, List<CombatEffect> effects) handler;
  bool learned = false;

  CombatSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetType,
    required this.handler,
  });

  // 实现copyWith方法
  CombatSkill copyWith({
    SkillID? id,
    String? name,
    String? description,
    SkillType? type,
    SkillTarget? targetType,
    void Function(List<CombatSkill> skills, List<CombatEffect> effects)?
        handler,
  }) {
    return CombatSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      handler: handler ?? this.handler,
    );
  }
}

class SkillCollection {
// 各属性可学习技能列表
  static final List<CombatSkill> metalAvailableSkills = [
    SkillCollection.metalPassive_0,
    SkillCollection.metalActive_0,
    SkillCollection.metalPassive_1,
    SkillCollection.metalActive_1,
    SkillCollection.metalActive_2,
  ];
  static final List<CombatSkill> waterAvailableSkills = [
    SkillCollection.waterPassive_0,
    SkillCollection.waterActive_0,
    SkillCollection.waterPassive_1,
    SkillCollection.waterActive_1,
    SkillCollection.waterActive_2,
  ];
  static final List<CombatSkill> woodAvailableSkills = [
    SkillCollection.woodPassive_0,
    SkillCollection.woodActive_0,
    SkillCollection.woodPassive_1,
    SkillCollection.woodActive_1,
    SkillCollection.woodActive_2,
  ];
  static final List<CombatSkill> fireAvailableSkills = [
    SkillCollection.firePassive_0,
    SkillCollection.fireActive_0,
    SkillCollection.firePassive_1,
    SkillCollection.fireActive_1,
    SkillCollection.fireActive_2,
  ];
  static final List<CombatSkill> earthAvailableSkills = [
    SkillCollection.earthPassive_0,
    SkillCollection.earthActive_0,
    SkillCollection.earthPassive_1,
    SkillCollection.earthActive_1,
    SkillCollection.earthActive_2,
  ];

  // 总的技能列表，包含所有被动和主动技能
  static final List<List<CombatSkill>> totalSkills = [
    SkillCollection.metalAvailableSkills,
    SkillCollection.waterAvailableSkills,
    SkillCollection.woodAvailableSkills,
    SkillCollection.fireAvailableSkills,
    SkillCollection.earthAvailableSkills,
  ];

  // 示例技能

  static final CombatSkill baseParry = CombatSkill(
    id: SkillID.parry,
    name: "基础格挡",
    description: "防守时，减少75%伤害，生效一次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.parryState.index].value = 0.75;
      effects[EffectID.parryState.index].times += 1;
    },
  );

  static final CombatSkill metalPassive_0 = CombatSkill(
    id: SkillID.metalPassive_0,
    name: "金属亲和力",
    description: "战斗时，额外获得50%的攻击力和防御力。\n\n我将以高达形态出击。",
    type: SkillType.passive,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.strengthen.index].type = EffectType.infinite;
      effects[EffectID.strengthen.index].value = 0.5;
    },
  );

  static final CombatSkill waterPassive_0 = CombatSkill(
    id: SkillID.waterPassive_0,
    name: "此消彼长",
    description:
        "受到伤害后，防御力减少，根据减少量的82%，提高攻击力，如果是法术伤害，还会吸收其能量，提升一次附魔比例。\n\n你先开枪我也能先打死你。",
    type: SkillType.passive,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.adjustAttribute.index].type = EffectType.infinite;
      effects[EffectID.adjustAttribute.index].value = 0.82;
    },
  );

  static final CombatSkill woodPassive_0 = CombatSkill(
    id: SkillID.woodPassive_0,
    name: "就地取材",
    description: "造成伤害后，根据伤害量的40%，回复生命。\n\n没有一滴血是原装的。",
    type: SkillType.passive,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.absorbBlood.index].type = EffectType.infinite;
      effects[EffectID.absorbBlood.index].value = 0.4;
    },
  );

  static final CombatSkill firePassive_0 = CombatSkill(
    id: SkillID.firePassive_0,
    name: "燃烧吧",
    description: "攻击时，获得100%附魔比例，造成无视防御的法术伤害。\n\n燃起来了。",
    type: SkillType.passive,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.enchanting.index].type = EffectType.infinite;
      effects[EffectID.enchanting.index].value = 1;
    },
  );

  static final CombatSkill earthPassive_0 = CombatSkill(
    id: SkillID.earthPassive_0,
    name: "承天载物",
    description: "受到伤害后，将物理伤害的50%和法术伤害的15%作为加成，提高下次攻击的攻击力。\n\n大地会记住一切。",
    type: SkillType.passive,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.accumulateAnger.index].type = EffectType.infinite;
      effects[EffectID.accumulateAnger.index].value = 0.5;
    },
  );

  static final CombatSkill metalActive_0 = CombatSkill(
    id: SkillID.metalActive_0,
    name: "双重打击",
    description: "下次攻击时，额外进行一次，生效一次。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.multipleHit.index].value = 1;
      effects[EffectID.multipleHit.index].times += 1;
    },
  );

  static final CombatSkill waterActive_0 = CombatSkill(
    id: SkillID.waterActive_0,
    name: "拖泥带水",
    description: "下次攻击时，减少50%的攻击力，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.enemyFront,
    handler: (skills, effects) {
      effects[EffectID.weakenAttack.index].value = 0.5;
      effects[EffectID.weakenAttack.index].times += 2;
    },
  );

  static final CombatSkill woodActive_0 = CombatSkill(
    id: SkillID.woodActive_0,
    name: "光合作用",
    description: "根据生命上限的12.5%的回复生命，生效一次",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.restoreLife.index].value = 0.125;
      effects[EffectID.restoreLife.index].times += 1;
    },
  );

  static final CombatSkill fireActive_0 = CombatSkill(
    id: SkillID.fireActive_0,
    name: "火舞旋风",
    description: "生命值降为1，根据降低的比例，提高伤害系数，并进行一次攻击。\n\n Explosion！",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.sacrificing.index].value = 1;
      effects[EffectID.sacrificing.index].times += 1;
    },
  );

  static final CombatSkill earthActive_0 = CombatSkill(
    id: SkillID.earthActive_0,
    name: "刚体",
    description: "下次受到伤害时，进行一次攻击。\n力的作用是相互的。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.revengeAtonce.index].value = 1;
      effects[EffectID.revengeAtonce.index].times += 1;
    },
  );

  static final CombatSkill metalPassive_1 = CombatSkill(
    id: SkillID.metalPassive_1,
    name: "双重打击",
    description: "双重打击可以施加给己方任一元素。",
    type: SkillType.passive,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      skills[1].targetType = SkillTarget.selfAny;
    },
  );

  static final CombatSkill waterPassive_1 = CombatSkill(
    id: SkillID.waterPassive_1,
    name: "拖泥带水",
    description: "拖泥带水可以施加给敌方任一元素。",
    type: SkillType.passive,
    targetType: SkillTarget.enemyAny,
    handler: (skills, effects) {
      skills[1].targetType = SkillTarget.enemyAny;
    },
  );

  static final CombatSkill woodPassive_1 = CombatSkill(
    id: SkillID.woodPassive_1,
    name: "光合作用",
    description: "光合作用可以施加给己方任一元素。",
    type: SkillType.passive,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      skills[1].targetType = SkillTarget.selfAny;
    },
  );

  static final CombatSkill firePassive_1 = CombatSkill(
    id: SkillID.firePassive_1,
    name: "火舞旋风",
    description: "火舞旋风可以施加给己方任一元素，并在生效后，切换其上场。",
    type: SkillType.passive,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      skills[1].targetType = SkillTarget.selfAny;
    },
  );

  static final CombatSkill earthPassive_1 = CombatSkill(
    id: SkillID.earthPassive_1,
    name: "刚体",
    description: "刚体可以施加给己方任一元素。",
    type: SkillType.passive,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      skills[1].targetType = SkillTarget.selfAny;
    },
  );

  static final CombatSkill metalActive_1 = CombatSkill(
    id: SkillID.metalActive_1,
    name: "金属亲和力",
    description: "战斗时，额外获得50%的攻击力和防御力，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.strengthen.index].value = 0.5;
      effects[EffectID.strengthen.index].times += 2;
    },
  );

  static final CombatSkill waterActive_1 = CombatSkill(
    id: SkillID.waterActive_1,
    name: "此消彼长",
    description: "受到伤害后，防御力减少，根据减少量的82%，提高攻击力，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.adjustAttribute.index].value = 0.82;
      effects[EffectID.adjustAttribute.index].times += 2;
    },
  );

  static final CombatSkill woodActive_1 = CombatSkill(
    id: SkillID.woodActive_1,
    name: "就地取材",
    description: "造成伤害时，根据伤害量的40%，回复生命，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.absorbBlood.index].value = 0.4;
      effects[EffectID.absorbBlood.index].times += 2;
    },
  );

  static final CombatSkill fireActive_1 = CombatSkill(
    id: SkillID.fireActive_1,
    name: "燃烧吧",
    description: "攻击时，获得100%附魔比例，造成无视防御的法术伤害，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.enchanting.index].value = 1;
      effects[EffectID.enchanting.index].times += 2;
    },
  );

  static final CombatSkill earthActive_1 = CombatSkill(
    id: SkillID.earthActive_1,
    name: "承天载物",
    description: "受到伤害后，将物理伤害的50%和法术伤害的15%作为加成，提高下次攻击的攻击力，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfAny,
    handler: (skills, effects) {
      effects[EffectID.accumulateAnger.index].value = 0.5;
      effects[EffectID.accumulateAnger.index].times += 2;
    },
  );

  static final CombatSkill metalActive_2 = CombatSkill(
    id: SkillID.metalActive_2,
    name: "巨人杀手",
    description: "攻击时，基于敌方当前生命值的25%，提高自身攻击力，生效一次。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.giantKiller.index].value = 0.25;
      effects[EffectID.giantKiller.index].times += 1;
    },
  );

  static final CombatSkill waterActive_2 = CombatSkill(
    id: SkillID.waterActive_2,
    name: "止水",
    description: "受到致命伤害时，生命值保持为1点，生效一次。\n\n区区致命伤。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.exemptionDeath.index].value = 1;
      effects[EffectID.exemptionDeath.index].times += 1;
    },
  );

  static final CombatSkill woodActive_2 = CombatSkill(
    id: SkillID.woodActive_2,
    name: "拔苗助长",
    description: "回复生命的溢出量可以超过基础生命上限，但是不能超过基础生命上限的100%，生效一次。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.increaseCapacity.index].value = 1;
      effects[EffectID.increaseCapacity.index].times += 1;
    },
  );

  static final CombatSkill fireActive_2 = CombatSkill(
    id: SkillID.fireActive_2,
    name: "灼烧",
    description: "造成的法术伤害，会使敌人烧伤，使其再次受到伤害时，将会追加本次伤害25%的伤害，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.hotDamage.index].value = 0.25;
      effects[EffectID.hotDamage.index].times += 2;
    },
  );

  static final CombatSkill earthActive_2 = CombatSkill(
    id: SkillID.earthActive_2,
    name: "地刺",
    description: "受到伤害时，将已损失生命值的25%作为攻击力，造成一次伤害系数为25%的物理伤害，生效两次。",
    type: SkillType.active,
    targetType: SkillTarget.selfFront,
    handler: (skills, effects) {
      effects[EffectID.rugged.index].value = 0.25;
      effects[EffectID.rugged.index].times += 2;
    },
  );
}
