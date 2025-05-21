import Foundation
import EventKit
import WorkoutKit
import HealthKit

class OpenAIService: ObservableObject {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    @Published var isLoading = false
    @Published var error: Error?
    
    private var apiKey: String = "" // Will be set later
    
    func setAPIKey(_ key: String) {
        print("Setting API key: \(key.prefix(10))...")
        apiKey = key
    }
    
    func generatePrompt(healthManager: HealthManager) async throws -> String {
        // Health Data
        var prompt = "\nWorkout Data:\n"
        for workout in healthManager.workouts.suffix(10) {
            prompt += "\nNew Workout: \(workout.workoutActivityType.name)\n"
            prompt += "Start: \(workout.startDate.formatted(date: .long, time: .shortened))\n"
            prompt += "End: \(workout.endDate.formatted(date: .long, time: .shortened))\n"
            prompt += String(format: "Duration: %.1f minutes\n", workout.duration/60)
            let desc = workout.description
            if !desc.isEmpty {
                prompt += "Description: \(desc)\n"
            }
            if let distance = workout.totalDistance?.doubleValue(for: .mile()) {
                prompt += String(format: "Distance: %.2f mi\n", distance)
            } else if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                prompt += String(format: "Distance: %.0f m\n", distance)
            }
            if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                prompt += "Calories: \(Int(calories)) kcal\n"
            }
            if let strokes = workout.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) {
                prompt += "Swimming Strokes: \(Int(strokes))\n"
            }
            if let flights = workout.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) {
                prompt += "Flights Climbed: \(Int(flights))\n"
            }
            // Device info
            if let device = workout.device {
                prompt += "Device: \(device.name ?? "Unknown") (\(device.model ?? ""))\n"
            }
            // Metadata
            if let meta = workout.metadata, !meta.isEmpty {
                prompt += "Metadata: "
                for (key, value) in meta {
                    prompt += "\(key): \(value), "
                }
                prompt += "\n"
            }
            // Workout Events (pauses, laps, etc.)
            if let events = workout.workoutEvents, !events.isEmpty {
                prompt += "Events: "
                for event in events {
                    prompt += "[\(event.type.rawValue) at \(event.dateInterval.start.formatted(date: .abbreviated, time: .shortened))] "
                }
                prompt += "\n"
            }
            // Heart Rate Summary
            do {
                let hrData = try await healthManager.fetchHeartRateData(for: workout)
                if !hrData.isEmpty {
                    let minHR = hrData.min() ?? 0
                    let maxHR = hrData.max() ?? 0
                    let avgHR = hrData.reduce(0, +) / Double(hrData.count)
                    prompt += String(format: "Heart Rate (bpm): min %.0f, max %.0f, avg %.0f\n", minHR, maxHR, avgHR)
                }
            } catch {
                prompt += "Heart Rate: unavailable\n"
            }
            // Workout Activities
            if !workout.workoutActivities.isEmpty {
                prompt += "Workout activities:\n"
                for activity in workout.workoutActivities {
                    prompt += "  - Type: \(activity.workoutConfiguration.activityType.name)\n"
                    prompt += "    Description: \(activity.workoutConfiguration.description)\n"
                    prompt += String(format: "    Duration: %.0f seconds\n", activity.duration)
                }
            }
            prompt += "_______________________\n"
        }
        print(prompt)
        return prompt
    }
    
    func sendMessage(_ message: String, healthManager: HealthManager) async throws -> String {
        guard !apiKey.isEmpty else {
            print("Error: API Key is empty")
            throw NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"])
        }

        let systemMessage = "This GPT acts as a personalized health and performance advisor for a former elite athlete—someone who competed at the Division 1 and National Team level and now uses their accumulated training experience to maintain a healthy, high-functioning lifestyle. The GPT blends the expertise of a fitness coach, a nutritionist, and a wellness consultant, offering tailored guidance in areas like strength, stability, speed, endurance, agility, power, and mobility. It avoids general fitness advice, instead building nuanced, evidence-informed plans that reflect the user's training background and desire for sustainable performance.The focus is on long-term health, vitality, and an active lifestyle, emphasizing a holistic and strategic approach."
        
        let context = """
        ================================================
        File: Fitness Metrics.md
        ================================================
        Fitness metrics give an athlete an idea of how all [[Systems of the Body]] are working correctly as a team, and where the gaps are.

        - [[Strength]]
        - [[Stability]]
        - [[Speed]]
        - [[Endurance]]
        - [[Agility]]
        - [[Power]]
        - [[Mobility]]


        ================================================
        File: Fitness Plan.md
        ================================================
        Build long lasting and sustainable [[Fitness]] for a long and healthy life.
        ### Workout Sequences
        Mandatory days:
        1. [[Upper Body]]
        2. [[Lower Body]]
        3. [[Cardio]]

        Optional days:
        - [[Cardio and Weights]]
        - [[Sports]]
        ### Appendices
        - [[Sports and Goals]]
        - [[Extra Training Sessions]]
        - [[Missing Exercises]]
        - [[Tracking Progress]]
        - [[Recovery]]
        - [[Nutrition]]


        ================================================
        File: 1. Days/Cardio and Weights.md
        ================================================
        A [[Workout Sequence]] that focuses on mixing cardio and weights. This workout is supposed to be intense.

        - [[Lower Body Dynamic Warmup]]
        - [[Upper Body Dynamic Warmup]]

        - [[Full Body Strength Training Session]]
        - [[Full Body Endurance Training Session]]

        - [[Lower Body Cooldown]]
        - [[Upper Body Cooldown]]


        ================================================
        File: 1. Days/Cardio.md
        ================================================
        A [[Workout Sequence]] that works entire body.

        - [[Lower Body Dynamic Warmup]]
        - [[Lower Body Endurance Training Session]]
        - [[Lower Body Cooldown]]


        ================================================
        File: 1. Days/Lower Body.md
        ================================================
        A [[Workout Sequence]] that works the Lower Body.

        - [[Lower Body Dynamic Warmup]]
        - [[Lower Body Strength Training Session]]
        - [[Lower Body Cooldown]]


        ================================================
        File: 1. Days/Sports.md
        ================================================
        A [[Workout Sequence]] that focuses on mixing cardio and weights. This workout is supposed to be intense.

        - [[Lower Body Dynamic Warmup]]
        - [[Upper Body Dynamic Warmup]]
        - [[Full Body Sport]]


        ================================================
        File: 1. Days/Upper Body.md
        ================================================
        A [[Workout Sequence]] that works the Upper Body.

        - [[Upper Body Dynamic Warmup]]
        - [[Upper Body Strength Training Session]]
        - [[Upper Body Cooldown]]


        ================================================
        File: 2. Appendices/Extra Training Sessions.md
        ================================================
        Combine any training session with a proper [[Warmup]] and a [[Cooldown]] and quickly get a [[Workout Sequence]]

        1. [[Complementary Upper Body Strength Training Session]]
        2. [[Fitness+ Workouts]]


        ================================================
        File: 2. Appendices/Missing Exercises.md
        ================================================
        Shoulders


        Core
        - Twist/rotation
            - Stability, Power
        - Carry loaded movement
            - Stability, Strength, Endurance

        Lower body
        - Lunge/unilateral
            - Mobility, Stability, Power

        Upper Body Plyometrics
        - Clap Push-Ups, Medicine Ball Slams, Plyometric Bench Press, Medicine Ball Chest Pass, Overhead Medicine Ball Throw, Plyo Pull-Ups, Burpee with Push-Up and Tuck Jump


        ================================================
        File: 2. Appendices/Nutrition.md
        ================================================



        ================================================
        File: 2. Appendices/Recovery.md
        ================================================
        The muscle system of the body is a complex system that is not only made of muscles but also joints, ligaments, tendons, etc. It is imperative that the user takes care of the whole system, not only the muscles, especially because an injury in one part of the body can lead to an injury in other parts of the body.

        [[Active Muscle Recovery]]

        Once per month:
        [[Physiotherapy]]
        [[Sleep]]


        ================================================
        File: 2. Appendices/Sports and Goals.md
        ================================================
        The real focus of the [[Fitness Plan]] is to maintain a high enough [[Fitness]] level to be able to play any [[Sports]] or get any of my [[Goals]] done at any given point in time during my life.


        ================================================
        File: 2. Appendices/Tracking Progress.md
        ================================================
        No track of weight or times will be made. We will constantly use Apple Health, the Fitness app and Fitness+, and the custom Workout app developed by me to track progress, thus an Apple Watch and an iPhone are key for this [[Fitness]] progress to be tracked.

        We will also get an InBody complete measurement once every 2 months if possible, so that we can track body weight, fat percentage, muscle and fat concentration and other very important metrics.

        Even if smart sources are amazing at letting us know how we are improving, Iit is imperative that the athlete listens to their body to find the correct effort and energy needed for getting workouts done so that we constantly work on our [[Mindfulness]] and [[Mind Muscle Connection]]. [[Sports and Goals]] performance is also a very good and important factor in determining if the [[Fitness]] level is improving.

        Lastly, we can also run [[Test Days]] to switch things up in the gym and also track how our [[Fitness]] is doing.
        """

        let formattingRules = "Use 3 or 4 emojis at most. Never use headers or subheaders in markdown, simply make titles and key points bold. Provided are the previous 5 workouts."

        var messages = [ChatMessage(role: "system", content: systemMessage + "\n\n" + formattingRules)]
        
        let dataPrompt = try await generatePrompt(healthManager: healthManager)
        
        messages.append(ChatMessage(role: "user", content: dataPrompt))
        let request = ChatCompletionRequest(model: "gpt-4o-mini", messages: messages)
        guard let url = URL(string: baseURL) else {
            print("Error: Invalid URL")
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(request)
            urlRequest.httpBody = encodedData
            if let jsonString = String(data: encodedData, encoding: .utf8) {
                print("Request JSON: \(jsonString)")
            }
        } catch {
            print("Error encoding request: \(error)")
            throw error
        }
        print("Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid HTTP response")
            throw URLError(.badServerResponse)
        }
        guard httpResponse.statusCode == 200 else {
            print("Error: API request failed with status code \(httpResponse.statusCode)")
            if let errorJson = String(data: data, encoding: .utf8) {
                print("Error response: \(errorJson)")
            }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
        }
        let decoder = JSONDecoder()
        do {
            let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
            guard let firstChoice = completionResponse.choices.first else {
                print("Error: No choices in response")
                throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response choices available"])
            }
            return firstChoice.message.content
        } catch {
            print("Error decoding response: \(error)")
            throw error
        }
    }
} 
