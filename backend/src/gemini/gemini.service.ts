import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { GoogleGenerativeAI, GenerativeModel } from '@google/generative-ai';
import {
  FoodAnalysisResult,
  FOOD_ANALYSIS_SYSTEM_PROMPT,
  DEFAULT_FOOD_ANALYSIS,
} from './gemini.constants';
import { AbsorptionProfile } from '../energy/energy.constants';

@Injectable()
export class GeminiService implements OnModuleInit {
  private readonly logger = new Logger(GeminiService.name);
  private genAI: GoogleGenerativeAI;
  private model: GenerativeModel;
  private isConfigured = false;

  onModuleInit() {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      this.logger.warn(
        'GEMINI_API_KEY not configured. Food analysis will use fallback values.',
      );
      return;
    }

    try {
      this.genAI = new GoogleGenerativeAI(apiKey);
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
      });
      this.isConfigured = true;
      this.logger.log('Gemini AI service initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize Gemini AI:', error);
    }
  }

  /**
   * Check if the Gemini service is properly configured
   */
  isReady(): boolean {
    return this.isConfigured;
  }

  /**
   * Analyze a food image using Gemini Vision API
   *
   * @param imageBuffer - The image data as a Buffer
   * @param mimeType - The MIME type of the image (e.g., 'image/jpeg')
   * @returns Food analysis result
   */
  async analyzeFoodImage(
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<FoodAnalysisResult> {
    if (!this.isConfigured) {
      this.logger.warn('Gemini not configured, returning default analysis');
      return DEFAULT_FOOD_ANALYSIS;
    }

    try {
      // Convert buffer to base64 for Gemini API
      const base64Image = imageBuffer.toString('base64');

      // Create the image part for multimodal input
      const imagePart = {
        inlineData: {
          data: base64Image,
          mimeType: mimeType,
        },
      };

      // Generate content with the image and system prompt
      const result = await this.model.generateContent([
        FOOD_ANALYSIS_SYSTEM_PROMPT,
        imagePart,
      ]);

      const response = result.response;
      const text = response.text();

      // Parse the JSON response
      const analysisResult = this.parseAnalysisResponse(text);

      this.logger.log(
        `Food analyzed: ${analysisResult.foodName} (GI: ${analysisResult.glycemicIndex}, Confidence: ${analysisResult.confidence})`,
      );

      return analysisResult;
    } catch (error) {
      this.logger.error('Error analyzing food image:', error);
      return {
        ...DEFAULT_FOOD_ANALYSIS,
        notes: `Analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      };
    }
  }

  /**
   * Parse and validate the Gemini response
   */
  private parseAnalysisResponse(responseText: string): FoodAnalysisResult {
    try {
      // Clean the response - remove markdown code blocks if present
      let cleanedText = responseText.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.slice(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.slice(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.slice(0, -3);
      }
      cleanedText = cleanedText.trim();

      const parsed = JSON.parse(cleanedText);

      // Validate and sanitize the response
      // Reject "Unknown Food" as a food name — use a generic fallback instead
      const rawFoodName = this.validateString(parsed.foodName, 'Food');
      const foodName =
        rawFoodName.toLowerCase() === 'unknown food' ? 'Food' : rawFoodName;

      return {
        foodName,
        absorptionProfile: this.validateAbsorptionProfile(
          parsed.absorptionProfile,
        ),
        glycemicIndex: this.validateNumber(parsed.glycemicIndex, 1, 100, 50),
        fullnessVolume: this.validateNumber(parsed.fullnessVolume, 0, 100, 40),
        estimatedSatietyMinutes: this.validateNumber(
          parsed.estimatedSatietyMinutes,
          10,
          480,
          120,
        ),
        confidence: this.validateNumber(parsed.confidence, 0, 1, 0.5),
        notes: parsed.notes || undefined,
      };
    } catch (error) {
      this.logger.error('Failed to parse Gemini response:', responseText);
      return {
        ...DEFAULT_FOOD_ANALYSIS,
        notes: 'Failed to parse AI response',
      };
    }
  }

  /**
   * Validate and return a string value
   */
  private validateString(value: unknown, defaultValue: string): string {
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
    return defaultValue;
  }

  /**
   * Validate absorption profile enum
   */
  private validateAbsorptionProfile(value: unknown): AbsorptionProfile {
    if (
      typeof value === 'string' &&
      Object.values(AbsorptionProfile).includes(value as AbsorptionProfile)
    ) {
      return value as AbsorptionProfile;
    }
    return AbsorptionProfile.BALANCED;
  }

  /**
   * Validate a number within a range
   */
  private validateNumber(
    value: unknown,
    min: number,
    max: number,
    defaultValue: number,
  ): number {
    if (typeof value === 'number' && !isNaN(value)) {
      return Math.max(min, Math.min(max, value));
    }
    return defaultValue;
  }

  /**
   * Analyze food from a URL (alternative method)
   *
   * @param imageUrl - URL of the food image
   * @returns Food analysis result
   */
  async analyzeFoodFromUrl(imageUrl: string): Promise<FoodAnalysisResult> {
    if (!this.isConfigured) {
      this.logger.warn('Gemini not configured, returning default analysis');
      return DEFAULT_FOOD_ANALYSIS;
    }

    try {
      // Fetch the image from URL
      const response = await fetch(imageUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch image: ${response.statusText}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      const contentType = response.headers.get('content-type') || 'image/jpeg';

      return this.analyzeFoodImage(buffer, contentType);
    } catch (error) {
      this.logger.error('Error fetching image from URL:', error);
      return {
        ...DEFAULT_FOOD_ANALYSIS,
        notes: `Failed to fetch image: ${error instanceof Error ? error.message : 'Unknown error'}`,
      };
    }
  }
}
