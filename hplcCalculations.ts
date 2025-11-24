export type HplcColumn = {
    lengthMm: number;
    diameterMm: number;
    particleSizeUm: number;
};

export type GradientStep = {
    time: number;
    percentB: number;
};

export type HplcScalingResult = {
    newFlowRate: number;
    newGradientTable: GradientStep[];
    flowRateScaleFactor: number;
    gradientTimeScaleFactor: number;
    originalLdpRatio: number;
    newLdpRatio: number;
    ldpChangePercent: number;
    isLdpCompliant: boolean;
};

export type Result<T> =
    | { success: true; data: T }
    | { success: false; error: string };

export const calculateHplcScaling = (
    originalColumn: HplcColumn,
    newColumn: HplcColumn,
    originalFlowRate: number,
    originalGradientTable: GradientStep[]
): Result<HplcScalingResult> => {
    if (originalColumn.diameterMm <= 0 || newColumn.diameterMm <= 0 ||
        originalColumn.particleSizeUm <= 0 || newColumn.particleSizeUm <= 0) {
        return { success: false, error: 'Invalid column dimensions.' };
    }

    try {
        // USP <621> Flow Rate Scaling
        const diameterRatioSq = Math.pow(newColumn.diameterMm / originalColumn.diameterMm, 2);
        const particleRatio = originalColumn.particleSizeUm / newColumn.particleSizeUm;

        const newFlowRate = originalFlowRate * diameterRatioSq * particleRatio;

        // Gradient Time Scaling
        const volumeRatio = (newColumn.lengthMm * Math.pow(newColumn.diameterMm, 2)) /
            (originalColumn.lengthMm * Math.pow(originalColumn.diameterMm, 2));

        const flowRatio = originalFlowRate / newFlowRate;
        const timeScaleFactor = flowRatio * volumeRatio;

        // Scale the entire gradient table
        const newGradientTable = originalGradientTable.map(step => ({
            time: step.time * timeScaleFactor,
            percentB: step.percentB
        }));

        // USP <621> L/dp Ratio Check
        const originalLdp = (originalColumn.lengthMm * 1000) / originalColumn.particleSizeUm;
        const newLdp = (newColumn.lengthMm * 1000) / newColumn.particleSizeUm;
        const ldpChange = ((newLdp - originalLdp) / originalLdp) * 100;

        const isCompliant = ldpChange >= -25 && ldpChange <= 50;

        return {
            success: true,
            data: {
                newFlowRate,
                newGradientTable,
                flowRateScaleFactor: newFlowRate / originalFlowRate,
                gradientTimeScaleFactor: timeScaleFactor,
                originalLdpRatio: originalLdp,
                newLdpRatio: newLdp,
                ldpChangePercent: ldpChange,
                isLdpCompliant: isCompliant
            }
        };
    } catch (e) {
        return { success: false, error: `Calculation error: ${e}` };
    }
};
