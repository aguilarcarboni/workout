import Foundation
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


        ================================================
        File: 3. Review/Acetylcholine.md
        ================================================



        ================================================
        File: 3. Review/Active Muscle Recovery.md
        ================================================
        Twice a week
        About 20-30 minutes
        Wednesdays and Sundays:

        1. [[Foam Rolling]]
        2. [[Percussive Therapy]]
        3. [[Lacrosse Ball]]
        4. Stretching


        ================================================
        File: 3. Review/Adrenal Fatigue.md
        ================================================
        Sympathetic nervous State is on
        Live like a lion
        21st century syndrome


        ================================================
        File: 3. Review/Bill Maeda.md
        ================================================



        ================================================
        File: 3. Review/Breathing during Exercise.md
        ================================================
        When performing exercises, it's generally recommended to **exhale during the concentric phase** (when you are exerting force, like lifting a weight) and **inhale during the eccentric phase** (when you are lowering the weight or returning to the starting position). This helps maintain proper breathing rhythm, supports core stability, and reduces the risk of holding your breath unintentionally, which can cause dizziness or increased blood pressure.


        ================================================
        File: 3. Review/Foam Rolling.md
        ================================================
        **What it does:**

        - Applies broad, sustained pressure to large muscle groups (e.g., quads, hamstrings).
        - Rolls out muscle tightness and helps break down muscle knots (trigger points).
        - Releases fascial tension and improves blood flow.

        **Benefits:**

        - Great for general maintenance of large muscle groups.
        - Increases circulation and tissue elasticity.
        - Reduces muscle soreness and stiffness.
        - Enhances range of motion.
        - Aids in recovery post-exercise.
        - Prevents chronic knot formation with regular use.

        **Cons:**

        - Less precise for smaller or deeper knots.
        - Can be uncomfortable for beginners or tight areas.
        - May require larger space and proper technique to be effective.
        - 
        **Tips:**

        - Roll slowly for 1–2 minutes per muscle group.
        - Pause and hold pressure on tender spots for 20–30 seconds.
        - Use after workouts or on rest days when muscles are warm.
        - Stay hydrated post-session to aid recovery.


        ================================================
        File: 3. Review/Idk.md
        ================================================
        Make sure to train exercise exercises and also bring actual functionality so something like one-sided weight, walking or sandbag training or stuff that is actually using other muscles along with what is being trained


        ================================================
        File: 3. Review/Lacrosse Ball.md
        ================================================
        **What It Does:**

        - Applies deep, pinpointed pressure to specific knots or small areas (e.g., glutes, shoulders).
        - Targets hard-to-reach trigger points.
        - Loosens tight fascia and relieves tension in smaller muscle groups.

        **Benefits:**

        - Highly targeted, ideal for stubborn or deep knots.
        - Improves joint mobility and localized flexibility.
        - Great for correcting muscle imbalances and relieving referred pain.
        - Can be done anywhere with minimal equipment.

        **Cons:**

        - Can be very intense and painful if pressure is too high.
        - Requires good body awareness and control.
        - Not suitable for large surface areas.

        **Tips:**

        - Apply pressure using body weight or hand for 20–30 seconds per spot.
        - Focus on breathing deeply to help the muscle relax.
        - Best done on rest days or after workouts for tight areas.
        - Follow up with stretching to maintain flexibility.


        ================================================
        File: 3. Review/Lower Body Dynamic Warmup.md
        ================================================
        A [[Dynamic Warmup]].


        ================================================
        File: 3. Review/Mind Muscle Connection.md
        ================================================
        It is clear that the mind and the body work together, and that the mind is the driver of the body. The mind must be in harmony with the body, so ensure working on breathing and the mind-muscle connection that it leads to an improvement in the system as a whole, not only in the muscles.

        Gets worse as the session goes on

        Henneman Size Principle
        Motor units are sections of muscle fibers used, they are recruited in a specific order based on their size during muscle activation, starting with the smallest and progressing to the largest

        For nerves to create more connections and recruit more motor units easier over time resistance training must have:
        - Stress
        - Tension
        - Damage

        5-15 sets per week per muscle
        30-80% of 1RM

        Most should be not to failure
        Not too much volume
        Add slow eccentric and fast concentric

        HRV is a good guideline for Neurological to muscle connection recovery.

        Electrolytes like salt, potassium, and magnesium can lead to much better muscle to mind connection


        ================================================
        File: 3. Review/Mindfulness.md
        ================================================



        ================================================
        File: 3. Review/Percussive Therapy.md
        ================================================
        **What It Does:**

        - Delivers rapid, targeted pulses to muscles.
        - Disrupts knots, increases local circulation, and relaxes muscle fibers.
        - Helps reduce muscle tension and soreness quickly.

        **Benefits:**

        - Fast and effective relief from deep knots.
        - Stimulates blood flow and reduces DOMS.
        - Enhances muscle recovery and performance.
        - Can be used for quick sessions or targeted relief.

        **Cons:**

        - Less effective for small, precise areas.
        - Can be intense for sensitive users or overused muscles.
        - Devices can be expensive and noisy.
        - Not ideal over bony areas or injuries.

        **Tips:**

        - Use for 30–60 seconds per muscle area.
        - Adjust speed and attachment for comfort and target area.
        - Avoid bony prominences and stay within a tolerable pressure range.
        - Use post-workout or during cooldown sessions.



        ================================================
        File: 3. Review/Squat to Hinge.md
        ================================================



        ================================================
        File: 3. Review/Test Days.md
        ================================================
        Test days are be [[Workout Sequence]] that are meant to be done not very often, so that the athlete does not get used to them and they serve as [[Fitness]] benchmarks.

        5k run test day
        - Aim for 35 min - stay in zone 3

        Body weight circuit test
        - 10 pull-ups, 
        - 20 push-ups, 
        - 30 air squats 
        - 40 mountain climbers. 
        Time how long it takes to complete 3 rounds with minimal rest.




        ================================================
        File: 3. Review/Upper Body Dynamic Warmup.md
        ================================================
        A [[Dynamic Warmup]].

        1. **Arm Circles (1-2 minutes)**
            - Stand with feet shoulder-width apart.
            - Extend arms parallel to the ground and make small forward circles for 30-45 seconds, gradually increasing circle size.
            - Reverse direction for another 30-45 seconds.
            - **Purpose**: Warms up shoulder joints and increases mobility.
        2. **Cat-Cow to Thoracic Rotation (1-2 minutes)**
            - Start in a tabletop position (hands and knees).
            - Flow through 5-8 cat-cow stretches (arch and round your back).
            - Then, thread one arm under your body, resting shoulder on the ground, and reverse to reach the arm upward, twisting your upper back (5 reps per side).
            - **Purpose**: Mobilizes spine, opens chest, and engages upper back.
        3. **Dynamic Chest Opener (1 minute)**
            - Stand tall, arms at your sides.
            - Swing both arms backward, squeezing shoulder blades together, then bring them forward into a wide hug motion (like hugging a tree).
            - Repeat for 45-60 seconds at a controlled pace.
            - **Purpose**: Activates chest, shoulders, and upper back.
        4. **Scapular Push-Ups (1-2 minutes)**
            - Start in a high plank position, keeping arms straight.
            - Retract shoulder blades together, then protract them forward without bending elbows (10-15 reps).
            - Follow with 5-10 slow push-ups to engage chest and triceps.
            - **Purpose**: Warms up scapular muscles and stabilizes shoulders.
        5. **Light Band or Bodyweight Resistance (2-3 minutes)**
            - **Option 1: Resistance Band Pull-Aparts**
                - Hold a light resistance band with both hands, arms extended forward.
                - Pull the band apart by moving arms outward, squeezing shoulder blades (12-15 reps, 2 sets).
            - **Option 2: Bodyweight Y-T-I Raises**
                - Lie face-down, arms extended overhead in a “Y” shape, thumbs up.
                - Lift arms slightly off the ground (5 reps), then move to a “T” (5 reps), and finally an “I” (arms by sides, 5 reps).
            - **Purpose**: Activates rear delts, traps, and rhomboids for pulling movements.
        6. **Transition to Cardio Finisher (1-2 minutes)**
            - Perform shadowboxing with light punches (jab-cross combinations) or high-rep bodyweight moves like alternating superman holds (lifting opposite arm and leg).
            - Keep it brisk to elevate heart rate, mimicking your cycling transition.
            - **Purpose**: Bridges to your main workout with full upper body engagement.

        **Tips**:

        - Perform movements smoothly, focusing on range of motion and control.
        - Adjust reps or duration to fit 6-10 minutes.
        - If you have access to a rower or battle ropes, 1-2 minutes of light rowing or rope slams can replace the cardio finisher for a more specific upper body transition.


        ================================================
        File: 3. Review/Appendices/Goals.md
        ================================================
        5K Run - 34:35
        10K Run -
        21K Run -
        42K Run - 


        ================================================
        File: 3. Review/Appendices/Physiotherapy.md
        ================================================
        Stretches


        ================================================
        File: Definitions/Dropset.md
        ================================================
        A dropset is finishing an [[Exercise]]'s set with some more, lower intensity sets, lowering the reps and/or weight so that we can ensure good form but less intensity at the end of a workout. Think of it as "squeezing the juice" out of your muscles.

        For example,
        - Bench press
            - 60kg for 6 reps (actual set)
            - 45 kg for 6 reps
            - 30 kg for 6 reps
            - 15 kg for 6 reps


        ================================================
        File: Definitions/Exercise.md
        ================================================
        A physical or mental activity that an athlete can do.


        ================================================
        File: Definitions/Fitness.md
        ================================================
        The ability to employ any of the [[Fitness Metrics]] at any point in your life with correct form for many and any different movements natural to the human body.

        On the other hand, it is imperative to have a very acute [[Mind Muscle Connection]] that ensures a system that can handle any physical activity as naturally and instinctively as possible, without much second thought, and can recover quickly.


        ================================================
        File: Definitions/Heart Rate Zones.md
        ================================================
        ## ﻿﻿Zone 1 
        Warm-up, recovery, or very light exercise. This is great for improving overall health and active recovery.
        ## Zone 2
        [[Aerobic Endurance]] base training. This is often recommended for long, steady-state cardio to improve metabolism. It's sustainable for longer durations without over-stressing your body.
        ## Zone 3 
        Moderate intensity. This zone improves [[Aerobic Endurance]]. You're working harder, burning more carbohydrates, and improving your ability to sustain effort over time.
        ## Zone 4 
        [[Anaerobic Endurance]] threshold training. This zone improves your [[Lactate Threshold]]. It's great for boosting [[Speed]] and [[Power]] but it's more taxing.
        ## Zone 5 
        Maximum effort. This is for high-intensity interval training (HIIT) or short bursts of all-out effort. It improves your VO2 max (maximum oxygen uptake), [[Power]], and [[Anaerobic Endurance]], but it's not sustainable for long periods and requires good recovery.


        ================================================
        File: Definitions/Lactate Threshold.md
        ================================================
        The point at which lactic acid builds up faster than your body can clear it


        ================================================
        File: Definitions/Superset.md
        ================================================
        Repeating two exercises in quick succession that use opposite muscles.


        ================================================
        File: Definitions/Workout Sequence.md
        ================================================
        A set of [[Workout]] that can be done in sequence to complete a single day of training that helps an athlete develop their [[Fitness]]. 

        Normally includes a [[Warmup]], [[Training Session]] and [[Cooldown]].


        ================================================
        File: Definitions/Workout.md
        ================================================
        A group of [[Exercise]] that together help an athlete improve any one, many or all of their [[Fitness Metrics]].

        A workout is responsible for defining the metrics it will modify, as well as the sets and reps for the [[Exercise]] that will be done, ensuring they align with the goals necessary to change the [[Fitness Metrics]].


        ================================================
        File: Definitions/Exercises/Back Isometric Exercise.md
        ================================================
        Cable Pullover
        - Variation: 7x7x7 using varying grips


        ================================================
        File: Definitions/Exercises/Balanced Calf Exercise.md
        ================================================
        Balanced Calf Raises


        ================================================
        File: Definitions/Exercises/Calisthenics Back Exercise.md
        ================================================
        Pull Ups


        ================================================
        File: Definitions/Exercises/Calisthenics Biceps Exercise.md
        ================================================
        Chin up


        ================================================
        File: Definitions/Exercises/Calisthenics Chest Exercise.md
        ================================================
        Dips


        ================================================
        File: Definitions/Exercises/Calisthenics Triceps Exercise.md
        ================================================
        Tricep Drips


        ================================================
        File: Definitions/Exercises/Chest Isometric Exercise.md
        ================================================
        Chest Flys


        ================================================
        File: Definitions/Exercises/Compound Back Exercise.md
        ================================================
        Lat Pulldowns


        ================================================
        File: Definitions/Exercises/Compound Back Lower Body Exercise.md
        ================================================
        Barbell Deadlifts


        ================================================
        File: Definitions/Exercises/Compound Chest Exercise.md
        ================================================
        Bench Press


        ================================================
        File: Definitions/Exercises/Compound Front Lower Body Exercise.md
        ================================================
        Barbell Back Squat


        ================================================
        File: Definitions/Exercises/Continuous Running Exercise.md
        ================================================
        Running continuously at a constant speed


        ================================================
        File: Definitions/Exercises/Hanging Core Crunch Exercise.md
        ================================================
        Hanging Leg Raises


        ================================================
        File: Definitions/Exercises/Hanging Core Hold Exercise.md
        ================================================
        L-Sit Hold


        ================================================
        File: Definitions/Exercises/Indoor Cycling Warmup Exercise.md
        ================================================
        Indoor Cycling


        ================================================
        File: Definitions/Exercises/Isolated Biceps Exercise.md
        ================================================
        Bicep curls
        Hammer Curls
        Preacher curls


        ================================================
        File: Definitions/Exercises/Isolated Shoulders Exercise.md
        ================================================
        Lateral raises
        Overhead press
        Face pulls


        ================================================
        File: Definitions/Exercises/Isolated Triceps Exercise.md
        ================================================
        Tricep pulldown
        Dips
        "Below the head"
        Over head pull


        ================================================
        File: Definitions/Exercises/Jump Rope Warmup Exercise.md
        ================================================



        ================================================
        File: Definitions/Fitness Metrics/Aerobic Endurance.md
        ================================================
        A type of [[Endurance]] that also requires [[Speed]], [[Strength]] and [[Power]] over long distances and sustained activity. It is defined as the heart and lungs' ability to deliver oxygen to working muscles during sustained activity.

        Best trained at:
        3-12 sets
        8-12 minutes

        Range of work to rest:
        1-1 ratio is good


        ================================================
        File: Definitions/Fitness Metrics/Agility.md
        ================================================



        ================================================
        File: Definitions/Fitness Metrics/Anaerobic Endurance.md
        ================================================
        A type of [[Endurance]] that also requires [[Speed]], [[Strength]] and [[Power]] focused on short bursts of high-intensity activity fueled by glycogen and without relying heavily on oxygen.

        Best trained at:
        3-12 sets

        Range of work to rest:
        - 3 to 1
        - 1 to 5





        ================================================
        File: Definitions/Fitness Metrics/Endurance.md
        ================================================
        The ability of an athlete to go through in various types of intensity of work over a long period of time.

        Types of endurance:
        - [[Muscular Endurance]]
        - [[Aerobic Endurance]]
        - [[Anaerobic Endurance]]


        ================================================
        File: Definitions/Fitness Metrics/Muscular Endurance.md
        ================================================
        A type of [[Endurance]] that also requires muscle [[Stability]] and [[Mobility]] and good [[Mind Muscle Connection]].

        A muscle's ability to perform repeated contractions against resistance for extended periods of time without injury or fatigue. The ability of your mitochondria to use oxygen to generate energy locally and also of your nerves to sustain contraction.

        Involves high reps and low weight. Try to really feel that stretch on the muscle, ensuring time under tension by doing the exercises in an almost isometric way, slow and controlled. Remember, when employing muscular endurance the mind is tired, so push hard, making sure we feel the tension to recruit more motor units even if we are tired, building more [[Mind Muscle Connection]].

        Best trained at a range of:
        12-25 or even 100 reps
        3-5 sets


        ================================================
        File: Definitions/Fitness Metrics/Power.md
        ================================================



        ================================================
        File: Definitions/Fitness Metrics/Speed.md
        ================================================



        ================================================
        File: Definitions/Muscles/Psoas.md
        ================================================
        Psoas major and minor

        Muscle that goes from the front of the leg to the lower back

        Flexing the leg
        Kicking the leg forwards
        Stabilizing the hip as well as flexing the hip

        Shares a tendon with the Iliacus. 
        Together they are called the illiapsoas

        If it’s tight, it leads to lower back pain. When the Psoas is tight it makes you have a faster breathing and vice versa.

        Stretches and workouts

        [https://youtu.be/UnVjlCcolS8?si=pDuDTUPXCmuk_bkf](https://youtu.be/UnVjlCcolS8?si=pDuDTUPXCmuk_bkf)

        Anterior reach
        Chaos training


        ================================================
        File: Definitions/Systems of the Body/Cardiorespiratory System.md
        ================================================
        [[Strength]]: no
        [[Stability]]: minimal
        [[Speed]]: yes
        [[Endurance]]: yes
        [[Agility]]: yes
        [[Power]]: minimal
        [[Mobility]]: no


        ================================================
        File: Definitions/Systems of the Body/Musculoskeletal System.md
        ================================================

        [[Strength]]: yes
        [[Stability]]: yes
        [[Speed]]: yes
        [[Endurance]]: yes
        [[Agility]]: yes
        [[Power]]: yes
        [[Mobility]]: yes


        ================================================
        File: Definitions/Systems of the Body/Systems of the Body.md
        ================================================
        The well-being of systems of the body will depend on how well [[Fitness Metrics]] are doing.

        [[Cardiorespiratory System]]
        [[Musculoskeletal System]]
        [[Nervous System]]
        [[Endocrine System]]
        [[Metabolic System]]
        [[Immune System]]



        ================================================
        File: Definitions/Training Sessions/Complementary Upper Body Strength Training Session.md
        ================================================
        A Complementary Upper Body [[Training Session]] focused on [[Strength]]. Tracks using Traditional Strength Training using Apple's WorkoutKit.
        ### Traditional Strength Training - Strength

        - [[Complementary Upper Body Calisthenics Warmup]]
        - [[Complementary Upper Body Strength]]


        ================================================
        File: Definitions/Training Sessions/Full Body Endurance Training Session.md
        ================================================
        A Full Body [[Training Session]] focused on [[Anaerobic Endurance]]. Tracks using Cycling and HIIT workouts from Apple's WorkoutKit.
        ### Cycling - Cardio Warmup

        - [[Lower Body Cardio Warmup]]

        ### HIIT - Plyometrics

        - [[Lower Body Plyometrics]]

        ### Indoor Run - Sprints

        - [[Interval Sprints]]


        ================================================
        File: Definitions/Training Sessions/Full Body Strength Training Session.md
        ================================================
        A Lower Body [[Training Session]] focused on [[Strength]]. Tracks using Traditional Strength Training using Apple's WorkoutKit.
        ### Traditional Strength Training - Functional Strength

        [[Upper Body Calisthenics Warmup]]

        [[Lower Body Calisthenics Warmup]]

        [[Upper Body Functional Strength]]

        [[Lower Body Functional Strength]]


        ================================================
        File: Definitions/Training Sessions/Lower Body Endurance Training Session.md
        ================================================
        A Lower Body [[Training Session]] focused on [[Aerobic Endurance]] and [[Anaerobic Endurance]]. Tracks using Cycling, Indoor Running and HIIT workouts from Apple's WorkoutKit.
        ### Cycling - Cardio Warmup

        - [[Lower Body Cardio Warmup]]

        ### Indoor Run - Paced Run

        - [[Paced Run]]

        ### HIIT - Plyometrics

        - [[Lower Body Plyometrics]]


        ================================================
        File: Definitions/Training Sessions/Lower Body Strength Training Session.md
        ================================================
        A Lower Body [[Training Session]] focused on [[Strength]]. Tracks using Cycling, Traditional Strength Training and Core workouts from Apple's WorkoutKit.
        ### Cycling - Cardio Warmup

        [[Lower Body Cardio Warmup]]

        ### Traditional Strength Training - Functional Strength

        [[Lower Body Hip Warmup]]

        [[Lower Body Functional Strength]]

        [[Lower Body Functional Stability]]

        ### Core - Functional Stability

        [[Core Functional Stability]]


        ================================================
        File: Definitions/Training Sessions/Training Session.md
        ================================================
        A session is a key part of a [[Workout Sequence]] that is simply a set of [[Workout]] with enough similar properties to be able to be tracked using one or more of Apple WorkoutKit's different types of exercises.

        See: https://developer.apple.com/documentation/HealthKit/HKWorkoutActivityType for a list of all sessions available to be tracked.


        ================================================
        File: Definitions/Training Sessions/Upper Body Strength Training Session.md
        ================================================
        A Lower Body [[Training Session]] focused on [[Strength]]. Tracks using Traditional Strength Training using Apple's WorkoutKit.
        ### Traditional Strength Training - Functional Strength

        [[Upper Body Calisthenics Warmup]]

        [[Upper Body Functional Strength]]

        [[Upper Body Muscular Endurance]]



        ================================================
        File: Definitions/Workout Types/Aerobic Endurance Workout.md
        ================================================
        A type of [[Endurance Workout]] that ensures you develop [[Aerobic Endurance]]. 

        Try to stay between [[Heart Rate Zones]] 3 and 4.


        ================================================
        File: Definitions/Workout Types/Agility Workout.md
        ================================================
        A type of [[Workout]] that helps an athlete build [[Agility]].


        ================================================
        File: Definitions/Workout Types/Anaerobic Endurance Workout.md
        ================================================
        A type of [[Endurance Workout]] that ensures you develop [[Anaerobic Endurance]]. 

        Try to stay between [[Heart Rate Zones]] 4 and 5.


        ================================================
        File: Definitions/Workout Types/Cooldown.md
        ================================================
        A type of [[Workout]] that helps build [[Mobility]] in joints and muscles and prevents injuries. 

        Should be done at the end of every workout with low to moderate intensity to ensure enhanced circulation, decrease of injury risk and promoting muscle relaxation for less muscle knots.


        ================================================
        File: Definitions/Workout Types/Dynamic Warmup.md
        ================================================
        A type of [[Warmup]] that focuses solely on joint and muscle [[Mobility]] and [[Mind Muscle Connection]] activation to get ready for a session.

        Heart rate does not need to increase much, we are simply getting the blood flowing to joints and muscles.


        ================================================
        File: Definitions/Workout Types/Endurance Workout.md
        ================================================
        A type of [[Workout]] that helps an athlete build [[Endurance]]. 


        ================================================
        File: Definitions/Workout Types/Functional Agility Workout.md
        ================================================
        A type of [[Agility Workout]] that also helps build desired properties that relate to the workout being done. 


        ================================================
        File: Definitions/Workout Types/Functional Stability Workout.md
        ================================================
        A type of [[Stability Workout]] that also helps build desired properties that relate to the workout being done. 

        In these workouts it is important to use weights or other resistance to assist your goals, as that will make the [[Stability]] part of the workout harder, while also building [[Strength]], [[Endurance]] or [[Power]]. The idea is to build a system that can be stable and balanced without losing out on other [[Fitness Metrics]], which is hard since [[Stability]] requires a lot of very fine-grained mind and muscle control.

        These exercises also help a lot to prevent and cure injuries, as you are stabilizing joints and muscles around an injured area while also strengthening the other [[Fitness Metrics]] that will help the area in the long term.


        ================================================
        File: Definitions/Workout Types/Functional Strength Workout.md
        ================================================
        A type of [[Strength Workout]] that also helps build desired properties that relate to the workout being done. 

        Normally, if we want strength that works well with other [[Fitness Metrics]], doing compound exercises instead of isolation is a good idea, since we are trying to build other attributes other than strength that are greatly increased when the body works as a whole system together. Also, make sure to be using weights to assist your workout as that dramatically increases strength gains. 

        Most important, we also work the [[Mind Muscle Connection]] because we are training to recruit more motor units over time. Keep rep counts low, effort high and go slow on the eccentric, then powerfully and rapidly in the concentric, ensuring time under tension and correct form. 

        For example,
        - Bench press also builds upper body [[Mobility]], [[Power]] and [[Stability]] in chest and shoulder muscles.


        ================================================
        File: Definitions/Workout Types/Functional Warmup.md
        ================================================
        A type of [[Warmup]] that also helps build desired properties that relate to the workout being done. 

        Functional warmups will mimic movements that relate to the work that will be done later, trying to use those muscles in a controlled and low intensity environment before the real work. They are a key part of training since they work as bridges between more basic warmups and the main work.

        Try to keep your [[Heart Rate Zones]] to a level 2 to ensure the heart is ready for more exercise. Don't go too hard on heavy, moderate weight or effort is ideal, get the heart rate going. Go slow and controlled, make sure you feel everything activating. 

        Most important, we also work the [[Mind Muscle Connection]] because we are training to activate efficiently the motor units that will help us later in the workout, ensuring we develop acute muscle control.

        For example,
        - Cycling helps with lower body [[Power]] and [[Aerobic Endurance]].
        - Calisthenics help build functional [[Strength]] and [[Power]].


        ================================================
        File: Definitions/Workout Types/Muscular Endurance Workout.md
        ================================================
        A type of [[Endurance Workout]] that ensures you develop [[Muscular Endurance]]. 


        ================================================
        File: Definitions/Workout Types/Stability Workout.md
        ================================================
        A type of [[Workout]] that helps an athlete build [[Stability]].

        Remember, stability workouts are intended to not only help joints and muscles, but also help how the brain can react and change how motor units are employed when it loses balance or a joint hurts, building more [[Mind Muscle Connection]].


        ================================================
        File: Definitions/Workout Types/Strength Workout.md
        ================================================
        A type of [[Workout]] that helps an athlete build [[Strength]].


        ================================================
        File: Definitions/Workout Types/Warmup.md
        ================================================
        A type of [[Workout]] that helps build [[Stability]] and [[Mobility]] in joints and muscles. 

        Should be done with low to moderate intensity that helps you get the blood flowing into your joints, muscles, and mind to get ready for exercise. 


        ================================================
        File: Definitions/Workouts/Complementary Upper Body Calisthenics Warmup.md
        ================================================
        A [[Functional Warmup]] that is also focused on building [[Strength]] and [[Power]].

        [[Superset]] to ensure quick warmup and high heart rate.

        [[Calisthenics Biceps Exercise]] - 2 sets of 8-10 reps
        [[Calisthenics Triceps Exercise]] - 2 sets of 8-10 reps


        ================================================
        File: Definitions/Workouts/Complementary Upper Body Strength.md
        ================================================
        A [[Strength Workout]].

        - [[Isolated Biceps Exercise]] - 3 sets of 10-15 reps
        - [[Isolated Triceps Exercise]] - 3 sets of 10-15 reps
        - [[Isolated Shoulders Exercise]] - 3 sets of 10-15 reps

        - [[Isolated Biceps Exercise]] - 3 sets of 10-15 reps
        - [[Isolated Triceps Exercise]] - 3 sets of 10-15 reps
        - [[Isolated Shoulders Exercise]] - 3 sets of 10-15 reps


        ================================================
        File: Definitions/Workouts/Core Functional Stability.md
        ================================================
        A [[Functional Stability Workout]] that also focuses on [[Aerobic Endurance]], [[Strength]] and [[Power]].

        [[Superset]] to ensure high intensity and high heart rate. Rest 30 seconds per set.

        [[Hanging Core Hold Exercise]] - 2 sets of 30 sec
        [[Hanging Core Crunch Exercise]] - 2 sets of 30 sec


        ================================================
        File: Definitions/Workouts/Full Body Sport.md
        ================================================
        A Full Body [[Training Session]] focused on [[Fitness]] Tracks using any of the sport workouts from Apple's WorkoutKit.

        Could be any of these:
        - Soccer
        - Basketball
        - Climbing
        - Hiking
        - Golf
        - Padel
        - Yoga
        - Pilates
        - Gymnastics
        - Swimming
        - Track and Field
        - Kickboxing
        - Boxing
        - Surfing
        - Hold


        ================================================
        File: Definitions/Workouts/Hill Sprints.md
        ================================================
        An [[Anaerobic Endurance Workout]]

        [[Interval Running Exercise]] - 5 x Sprint uphill then walk down to recover / Zone 3-4


        ================================================
        File: Definitions/Workouts/Interval Sprints.md
        ================================================
        An [[Anaerobic Endurance Workout]]

        [[Interval Running Exercise]] - 3x400m / Zone 5



        ================================================
        File: Definitions/Workouts/LSD Run.md
        ================================================
        An [[Aerobic Endurance Workout]] and [[Muscular Endurance Workout]]

        [[Continuous Running Exercise]] - 60 to 90 min / Zone 2



        ================================================
        File: Definitions/Workouts/Lower Body Cardio Warmup.md
        ================================================
        A [[Functional Warmup]] that is also focused on building [[Aerobic Endurance]], [[Agility]] and [[Speed]].

        Choose one (5 minutes):
        - [[Jump Rope Warmup Exercise]]
        - [[Indoor Cycling Warmup Exercise]]


        ================================================
        File: Definitions/Workouts/Lower Body Cooldown.md
        ================================================
        A [[Cooldown]]


        ================================================
        File: Definitions/Workouts/Lower Body Functional Stability.md
        ================================================
        A [[Functional Stability Workout]] that is also focused on building [[Strength]] and [[Power]].

        [[Balanced Calf Exercise]] - 3 sets of 20 reps


        ================================================
        File: Definitions/Workouts/Lower Body Functional Strength.md
        ================================================
        A [[Functional Strength Workout]] focused on also building [[Mobility]], [[Stability]] and [[Power]].

        [[Compound Front Lower Body Exercise]] - 3 sets of 4-8 reps
        [[Compound Back Lower Body Exercise]] - 3 sets of 4-8 reps


        ================================================
        File: Definitions/Workouts/Lower Body Hip Warmup.md
        ================================================
        A [[Functional Warmup]] that is also focused on building [[Strength]] and [[Power]].

        [[Superset]] to ensure quick warmup and high heart rate.

        [[Adductors Exercise]] - 2 sets of 12-15 reps
        [[Abductors Exercise]] - 2 sets of 12-15 reps


        ================================================
        File: Definitions/Workouts/Lower Body Plyometrics.md
        ================================================
        An [[Anaerobic Endurance Workout]].

        Jump rope - 3 sets of 1:30 on, 30 off / Zone 4


        ================================================
        File: Definitions/Workouts/Paced Run.md
        ================================================
        An [[Aerobic Endurance Workout]] and [[Anaerobic Endurance Workout]]

        Mix both endurances by running at Zone 5 but over longer periods of time.

        [[Continuous Running Exercise]] - 30 min / 5km


        ================================================
        File: Definitions/Workouts/Upper Body Calisthenics Warmup.md
        ================================================
        A [[Functional Warmup]] that is also focused on building [[Strength]] and [[Power]].

        [[Superset]] to ensure quick warmup and high heart rate.

        [[Calisthenics Back Exercise]] - 2 sets of 8-10 reps
        [[Calisthenics Chest Exercise]] - 2 sets of 8-10 reps


        ================================================
        File: Definitions/Workouts/Upper Body Functional Strength.md
        ================================================
        A [[Functional Strength Workout]] focused on also building [[Mobility]], [[Stability]] and [[Power]].

        [[Dropset]] to ensure we work to our last drop of energy.

        [[Compound Chest Exercise]] - 3 sets of 4-8 reps
        [[Compound Back Exercise]] - 3 sets of 4-8 reps


        ================================================
        File: Definitions/Workouts/Upper Body Muscular Endurance.md
        ================================================
        A [[Muscular Endurance Workout]].

        [[Chest Isometric Exercise]] - 3 sets of 15-20 reps
        [[Back Isometric Exercise]] - 3 sets of 15-20 reps

        """

        let formattingRules = "Use 3 or 4 emojis at most. Never use headers or subheaders in markdown, simply make titles and key points bold."

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
