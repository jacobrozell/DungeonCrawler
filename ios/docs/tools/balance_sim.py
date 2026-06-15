#!/usr/bin/env python3
"""Offline balance model for Dungeon Divers.

Replicates the core combat / scaling / economy math from Balance.swift to
estimate pacing WITHOUT a device. This is an *approximation* (expected-value
combat, auto-battle heuristic, auto level-up + shop) used to sanity-check the
feel before playtesting. Keep constants in sync with Balance.swift by hand.
"""
import math

# --- Balance.swift constants ---
MANA_REGEN = 2
CRIT_MULT = 2.0
MAGIC_BONUS = 5
MAGIC_COST, HEAVY_COST, POISON_COST = 8, 5, 4
HEAVY_MULT = 1.8
ENEMY_ENDLESS_HP_GROWTH = 1.10
ENEMY_ENDLESS_ATK_GROWTH = 1.06
SHOP_GROWTH = 1.6
PRESTIGE_DIV = 100.0

def hit_chance(luck):            # roll(0..9) >= luck
    return max(0.0, min(1.0, (10 - luck) / 10))

def crit_chance(player_luck):
    return max(5, (10 - player_luck) * 3) / 100

def enemy_stats(layer, idx):
    scale = layer - 1
    post = max(0, layer - 5)
    hp, atk, dfn, luck = 50 + 15*scale, 15 + 15*scale, 5 + 5*scale, 5
    if scale + 1 >= 4: luck = 3
    if post > 0: luck = 1
    is_boss = (idx == 5)
    if is_boss and layer == 5:           # dragon
        hp, atk, dfn = 150, 100, 0
    elif is_boss:
        hp, atk, dfn = hp+15, atk+10, max(0, dfn-5)
    if post > 0:
        hp = round(hp * ENEMY_ENDLESS_HP_GROWTH**post)
        atk = round(atk * ENEMY_ENDLESS_ATK_GROWTH**post)
        dfn = round(dfn * ENEMY_ENDLESS_ATK_GROWTH**post)
    return hp, atk, dfn, luck, is_boss

class Player:
    def __init__(self, atk_mult=1.0, hp_mult=1.0, gold_mult=1.0):
        self.maxhp = round(60*hp_mult); self.hp = self.maxhp
        self.atk = round(25*atk_mult)
        self.dfn = 10; self.luck = 3
        self.maxmana = 20; self.mana = 20
        self.level = 1; self.gold = 0; self.gold_mult = gold_mult
        self.owned = {}
    def avg_turn_damage(self, e_def):
        # auto picks the strongest affordable move; approximate expected dmg.
        if self.mana >= MAGIC_COST:
            self.mana -= MAGIC_COST; dmg = self.atk + MAGIC_BONUS  # ignores def, always hits
        elif self.mana >= POISON_COST:
            self.mana -= POISON_COST; dmg = max(1, self.atk//2 - e_def) + self.level*2  # + dot approx
        elif self.mana >= HEAVY_COST:
            self.mana -= HEAVY_COST
            base = max(1, round(self.atk*HEAVY_MULT) - e_def)
            dmg = hit_chance(self.luck) * base * (1 + crit_chance(self.luck))
        else:
            base = max(1, self.atk - e_def)
            dmg = hit_chance(self.luck) * base * (1 + crit_chance(self.luck))
        self.mana = min(self.maxmana, self.mana + MANA_REGEN)
        return dmg
    def levelup(self):
        pick = self.level % 3
        self.level += 1
        if pick == 0: self.maxhp += 20; self.atk += 5; self.dfn += 5
        elif pick == 1: self.atk += 10; self.maxhp += 10; self.dfn += 5
        else: self.dfn += 10; self.atk += 5; self.maxhp += 10
        self.maxmana += 5; self.mana = self.maxmana; self.hp = self.maxhp
    def shop(self):
        perms = [("wh",40,"atk",5),("tw",40,"dfn",5),("hv",50,"hp",15),("lk",60,"luck",1)]
        for key,base,stat,amt in perms:
            n = self.owned.get(key,0)
            price = round(base * SHOP_GROWTH**n)
            if self.gold >= price:
                self.gold -= price; self.owned[key]=n+1
                if stat=="atk": self.atk+=amt
                elif stat=="dfn": self.dfn+=amt
                elif stat=="hp": self.maxhp+=amt; self.hp=self.maxhp
                elif stat=="luck": self.luck=max(1,self.luck-1)

def simulate(atk_mult=1.0, hp_mult=1.0, gold_mult=1.0, max_layer=40, verbose=False):
    p = Player(atk_mult, hp_mult, gold_mult)
    run_gold = 0; total_turns = 0
    layer = 1
    while layer <= max_layer:
        layer_turns = 0
        for idx in range(1, 6):
            ehp, eatk, edef, eluck, boss = enemy_stats(layer, idx)
            p.mana = min(p.maxmana, p.mana + 5)  # small top-up between fights (dodge/level feel)
            turns = 0
            while ehp > 0 and turns < 1000:
                ehp -= p.avg_turn_damage(edef)
                turns += 1
                if ehp <= 0: break
                # enemy retaliates (expected)
                p.hp -= hit_chance(eluck) * max(0, eatk - p.dfn)
                if p.hp <= 0:
                    return dict(died_layer=layer, died_enemy=idx, total_turns=total_turns+layer_turns+turns,
                                level=p.level, gold_earned=run_gold, pending_shards=int(math.sqrt(run_gold/PRESTIGE_DIV)))
            layer_turns += turns
            gold = round((eatk * layer) * gold_mult)  # generateGold = atk*level(~layer)
            p.gold += gold; run_gold += gold
            if p.hp < p.maxhp*0.5: p.hp = min(p.maxhp, p.hp + 10*p.level)  # heal approx
        if verbose:
            print(f"  layer {layer:>2}: {layer_turns:>3} turns, atk {p.atk:>4}, hp {p.maxhp:>4}, gold {p.gold:>8}")
        total_turns += layer_turns
        p.levelup(); p.shop()
        layer += 1
    return dict(cleared=max_layer, total_turns=total_turns, level=p.level,
                gold_earned=run_gold, pending_shards=int(math.sqrt(run_gold/PRESTIGE_DIV)))

if __name__ == "__main__":
    print("=== Run 1 (no prestige) ===")
    r = simulate(verbose=True)
    print(r)
    print("\n=== Campaign-only (layers 1-5) ===")
    print(simulate(max_layer=5))
    print("\n=== With prestige: Might x5 (+25% atk), Fortune x5 (+40% gold) ===")
    print(simulate(atk_mult=1.25, gold_mult=1.40, verbose=True))
