
export const formatNumber = (num: number): string => {
  if (num < 1000) return num.toFixed(1);
  const suffixes = ['', 'k', 'M', 'B', 'T', 'Q', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc', 'Ud', 'Dd', 'Td', 'Qad', 'Qid', 'Sxd', 'Spd', 'Ocd', 'Nod', 'Vg'];
  const suffixNum = Math.floor(("" + Math.floor(num)).length / 3);
  let shortValue = parseFloat((suffixNum !== 0 ? (num / Math.pow(1000, suffixNum)) : num).toPrecision(3));
  if (shortValue % 1 !== 0) {
    shortValue = parseFloat(shortValue.toFixed(1));
  }
  return shortValue + (suffixes[suffixNum] || 'e+');
};

export const calculateCost = (base: number, multiplier: number, level: number): number => {
  return Math.floor(base * Math.pow(multiplier, level));
};

/**
 * Calculates the number of items that can be purchased and their total cost.
 */
export const calculateMaxBuy = (baseCost: number, costMultiplier: number, currentLevel: number, availableResource: number, mode: number | 'MAX') => {
  if (mode === 1) {
    return { count: 1, cost: calculateCost(baseCost, costMultiplier, currentLevel) };
  }
  
  if (mode === 10) {
    let totalCost = 0;
    for(let i=0; i<10; i++) {
      totalCost += calculateCost(baseCost, costMultiplier, currentLevel + i);
    }
    return { count: 10, cost: totalCost };
  }

  // MAX Mode
  let limit = typeof mode === 'number' ? mode : 1000;
  let count = 0;
  let totalCost = 0;
  let nextCost = calculateCost(baseCost, costMultiplier, currentLevel);

  while (totalCost + nextCost <= availableResource && count < limit) {
    totalCost += nextCost;
    count++;
    nextCost = calculateCost(baseCost, costMultiplier, currentLevel + count);
  }
  
  return { count: count || 1, cost: count ? totalCost : nextCost };
};
