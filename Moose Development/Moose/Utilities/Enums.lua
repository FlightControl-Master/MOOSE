ENUMS = {}

ENUMS.ROE = {
  HoldFire = 1,
  ReturnFire = 2,
  OpenFire = 3,
  WeaponFree = 4
  }
  
ENUMS.ROT = {
  NoReaction = 1,
  PassiveDefense = 2,
  EvadeFire = 3,
  Vertical = 4
}

ENUMS.WeaponFlag={
  -- Bombs
  LGB=2,
  TvGB=4,
  SNSGB=8,
  HEBomb=16,
  Penetrator=32,
  NapalmBomb=64,
  FAEBomb=128,
  ClusterBomb=256,
  Dispencer=512,
  CandleBomb=1024,
  ParachuteBomb=2147483648,
  GuidedBomb=14, -- (LGB + TvGB + SNSGB)
  AnyUnguidedBomb=2147485680, -- (HeBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb)
  AnyBomb=2147485694, -- (GuidedBomb + AnyUnguidedBomb)
  -- Rockets
  LightRocket=2048,
  MarkerRocket=4096,
  CandleRocket=8192,
  HeavyRocket=16384,
  AnyRocket=30720  -- (LightRocket + MarkerRocket + CandleRocket + HeavyRocket)  
}