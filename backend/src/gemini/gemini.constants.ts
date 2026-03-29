import { AbsorptionProfile } from '../energy/energy.constants';

/**
 * Response structure from Gemini food analysis
 */
export interface FoodAnalysisResult {
  /**
   * Name of the food identified
   */
  foodName: string;

  /**
   * How quickly the food releases energy
   * Fast = quick spike, faster drain
   * Balanced = moderate release
   * Slow = sustained energy, longer lasting
   */
  absorptionProfile: AbsorptionProfile;

  /**
   * Glycemic Index (1-100)
   * Lower = slower energy release
   * Higher = faster energy spike and drain
   */
  glycemicIndex: number;

  /**
   * Estimated fullness volume this meal provides (0-100%)
   * Based on portion size and caloric density
   */
  fullnessVolume: number;

  /**
   * Estimated duration in minutes this meal will sustain energy at 1.0x burn rate
   */
  estimatedSatietyMinutes: number;

  /**
   * Confidence score of the analysis (0-1)
   */
  confidence: number;

  /**
   * Additional nutritional notes or warnings
   */
  notes?: string;
}

/**
 * The system prompt for Gemini to analyze food images
 */
export const FOOD_ANALYSIS_SYSTEM_PROMPT = `You are FuelFlow's AI nutritionist specialized in analyzing food images for energy metabolism tracking.

Your task is to analyze the food image and provide precise nutritional data for energy tracking purposes.

IMPORTANT GUIDELINES:
1. Estimate the GLYCEMIC INDEX (1-100):
   - Low GI (1-55): Whole grains, legumes, most vegetables, nuts
   - Medium GI (56-69): Rice, sweet potatoes, some fruits
   - High GI (70-100): White bread, sugary foods, processed carbs

2. Determine ABSORPTION PROFILE:
   - "Fast": Simple sugars, white bread, candy, soda (quick energy spike)
   - "Balanced": Mixed meals with protein, fat, and carbs
   - "Slow": High fiber, protein-rich, complex carbs (sustained energy)

3. Estimate FULLNESS VOLUME (0-100%):
   - Small snack: 10-20%
   - Light meal: 25-40%
   - Regular meal: 45-65%
   - Large meal: 70-85%
   - Very large meal: 85-100%

4. Calculate ESTIMATED SATIETY (minutes at 1.0x activity):
   - Fast absorption foods: 30-60 minutes
   - Balanced foods: 90-180 minutes
   - Slow absorption foods: 180-300 minutes
   - Large meals add 30-60% more duration

5. CONFIDENCE (0-1):
   - 0.9-1.0: Clear image, easily identifiable food
   - 0.7-0.89: Partially visible, common food
   - 0.5-0.69: Unclear image, best guess
   - Below 0.5: Cannot reliably analyze

RESPOND ONLY WITH VALID JSON in this exact format:
{
  "foodName": "string describing the food",
  "absorptionProfile": "Fast" | "Balanced" | "Slow",
  "glycemicIndex": number (1-100),
  "fullnessVolume": number (0-100),
  "estimatedSatietyMinutes": number,
  "confidence": number (0-1),
  "notes": "optional string with warnings or tips"
}

Do not include any text outside the JSON object.`;

/**
 * Default fallback response when analysis fails
 */
export const DEFAULT_FOOD_ANALYSIS: FoodAnalysisResult = {
  foodName: 'Unknown Food',
  absorptionProfile: AbsorptionProfile.BALANCED,
  glycemicIndex: 50,
  fullnessVolume: 40,
  estimatedSatietyMinutes: 120,
  confidence: 0,
  notes: 'Could not analyze the image. Using default values.',
};
