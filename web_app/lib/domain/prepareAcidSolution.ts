export type AcidPrepResult = {
  stockMolarity: number;
  volumeNeededMl: number;
  instructions: string;
};

export type Result<T> = 
  | { success: true; data: T }
  | { success: false; error: string };

export const prepareAcidSolution = (
  stockPercent: number,
  stockDensity: number,
  mw: number,
  basicity: number,
  targetConc: number,
  isMolarity: boolean,
  finalVolMl: number
): Result<AcidPrepResult> => {
  if (stockPercent <= 0 || stockPercent > 100) 
    return { success: false, error: 'Invalid stock concentration.' };
  
  const stockM = (stockPercent * stockDensity * 10) / mw;
  const targetM = isMolarity ? targetConc : targetConc / basicity;

  if (targetM > stockM)
    return { success: false, error: 'Target exceeds stock concentration.' };

  const vol = (targetM * finalVolMl) / stockM;
  return {
    success: true,
    data: {
      stockMolarity: stockM,
      volumeNeededMl: vol,
      instructions: `Measure ${vol.toFixed(1)} mL of acid. Add slowly to ~${(finalVolMl * 0.6).toFixed(0)} mL water. Dilute to ${finalVolMl.toFixed(0)} mL.`
    }
  };
};
