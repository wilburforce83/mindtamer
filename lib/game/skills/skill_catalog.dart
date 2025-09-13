import 'skill.dart';

class SkillCatalog {
  // 3 skills per class: basic, special(4cd), support (buff/debuff)
  static final Map<String, List<Skill>> byClass = {
    'Sage': [
      const Skill(
        id: 'Sage.basic',
        name: 'Mind Tap',
        description: 'A precise strike empowered by insight.',
        type: SkillType.basic,
        power: 6,
        cooldown: 0,
        melee: false,
      ),
      const Skill(
        id: 'Sage.special',
        name: 'Ward Burst',
        description: 'Release a protective pulse that harms foes.',
        type: SkillType.special,
        power: 10,
        cooldown: 4,
        melee: false,
      ),
      const Skill(
        id: 'Sage.support',
        name: 'Clarity',
        description: 'Sharpen senses, increasing attack briefly.',
        type: SkillType.support,
        power: 0,
        cooldown: 3,
        targetSelf: true,
        effect: SkillEffect(key: 'atk+', magnitude: 2, duration: 3),
        melee: false,
      ),
    ],
    'Warden': [
      const Skill(id:'Warden.basic', name:'Shield Bash', description:'A stout bash behind a steady guard.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Warden.special', name:'Bulwark Slam', description:'Crushes guard into a heavy strike.', type:SkillType.special, power:10, cooldown:4, melee:true),
      const Skill(id:'Warden.support', name:'Guard Up', description:'Raise defense for a few turns.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'def+', magnitude:2, duration:3), melee:false),
    ],
    'Trickster': [
      const Skill(id:'Trickster.basic', name:'Feint', description:'Quick cut that sets up advantage.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Trickster.special', name:'Ambush', description:'Evasive lunge for strong damage.', type:SkillType.special, power:10, cooldown:4, melee:true),
      const Skill(id:'Trickster.support', name:'Weaken', description:'Sap the foe’s power briefly.', type:SkillType.support, power:0, cooldown:3, targetSelf:false, effect:SkillEffect(key:'atk-', magnitude:2, duration:2), melee:false),
    ],
    'Seer': [
      const Skill(id:'Seer.basic', name:'Foresight Bolt', description:'A volley guided by prediction.', type:SkillType.basic, power:6, cooldown:0, melee:false),
      const Skill(id:'Seer.special', name:'Vision Flare', description:'A flash that disrupts and harms.', type:SkillType.special, power:10, cooldown:4, melee:false),
      const Skill(id:'Seer.support', name:'Expose', description:'Lower the foe’s guard briefly.', type:SkillType.support, power:0, cooldown:3, targetSelf:false, effect:SkillEffect(key:'def-', magnitude:2, duration:2), melee:false),
    ],
    'Artificer': [
      const Skill(id:'Artificer.basic', name:'Wrench Whack', description:'Reliable strike with a tool.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Artificer.special', name:'Gadget Burst', description:'Unleash a compact explosive.', type:SkillType.special, power:10, cooldown:4, melee:false),
      const Skill(id:'Artificer.support', name:'Tune-Up', description:'Increase attack slightly for a bit.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'atk+', magnitude:2, duration:2), melee:false),
    ],
    'Empath': [
      const Skill(id:'Empath.basic', name:'Soft Strike', description:'Gentle but effective hit.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Empath.special', name:'Radiant Pulse', description:'Healing light that hurts foes.', type:SkillType.special, power:9, cooldown:4, melee:false),
      const Skill(id:'Empath.support', name:'Soothe', description:'Minor heal over a few turns.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'regen', magnitude:3, duration:3), melee:false),
    ],
    'Sentinel': [
      const Skill(id:'Sentinel.basic', name:'Measured Cut', description:'Controlled frontline strike.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Sentinel.special', name:'Counterline', description:'Punishes overreach decisively.', type:SkillType.special, power:10, cooldown:4, melee:true),
      const Skill(id:'Sentinel.support', name:'Form Up', description:'Bolster defense briefly.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'def+', magnitude:2, duration:2), melee:false),
    ],
    'Oracle': [
      const Skill(id:'Oracle.basic', name:'Bind Sigil', description:'Tether strike with order.', type:SkillType.basic, power:6, cooldown:0, melee:false),
      const Skill(id:'Oracle.special', name:'Edict', description:'Impose harm through decree.', type:SkillType.special, power:10, cooldown:4, melee:false),
      const Skill(id:'Oracle.support', name:'Cleanse', description:'Remove a negative status from self.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'cleanse', magnitude:1, duration:0), melee:false),
    ],
    'Shadow': [
      const Skill(id:'Shadow.basic', name:'Cut', description:'A swift slicing attack.', type:SkillType.basic, power:6, cooldown:0, melee:true),
      const Skill(id:'Shadow.special', name:'Bleed', description:'Strike that causes minor bleed.', type:SkillType.special, power:9, cooldown:4, melee:true),
      const Skill(id:'Shadow.support', name:'Shroud', description:'Reduce damage taken briefly.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'guard', magnitude:2, duration:2), melee:false),
    ],
    'Alchemist': [
      const Skill(id:'Alchemist.basic', name:'Vial Toss', description:'A thrown vial explodes lightly.', type:SkillType.basic, power:6, cooldown:0, melee:false),
      const Skill(id:'Alchemist.special', name:'Concoction', description:'A potent brew detonates.', type:SkillType.special, power:10, cooldown:4, melee:false),
      const Skill(id:'Alchemist.support', name:'Catalyze', description:'Slightly boost next attack.', type:SkillType.support, power:0, cooldown:3, targetSelf:true, effect:SkillEffect(key:'focus', magnitude:1, duration:2), melee:false),
    ],
  };

  static List<Skill> forClass(String classKey) => byClass[classKey] ?? byClass['Sage']!;
}
