import Testing

@testable import ElementaryDOM

@Suite
struct AnimatedValueTests {
    @Test
    func progressesAnimation() {
        var value = AnimatedValue(value: TestValue(0))
        value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 1)))
        #expect(value.presentation == 0)
        value.progressToTime(0.2)
        #expect(value.presentation == 2)
        value.progressToTime(0.4)
        #expect(value.presentation == 4)
        value.progressToTime(0.6)
        #expect(value.presentation == 6)
        value.progressToTime(0.8)
        #expect(value.presentation == 8)
        value.progressToTime(1.0)
        #expect(value.presentation == 10)
        value.progressToTime(1.2)
        #expect(value.isAnimating == false)
        #expect(value.presentation == 10)
        value.progressToTime(1.4)
        #expect(value.presentation == 10)
    }

    @Test
    func delaysAnimation() {
        var value = AnimatedValue(value: TestValue(0))
        value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 1).delay(0.5)))
        #expect(value.progressToEnd(sampling: 0.2) == [0, 0, 0, 1, 3, 5, 7, 9, 10])
    }

    @Test
    func speedsUpAnimation() {
        var value = AnimatedValue(value: TestValue(0))
        value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 1).speed(2)))
        #expect(value.progressToEnd(sampling: 0.2) == [0, 4, 8, 10])
    }

    @Test
    func combinesDelaysAndSpeeds() {
        var value = AnimatedValue(value: TestValue(0))
        value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 2).speed(2).delay(0.5)))
        #expect(value.progressToEnd(sampling: 0.2) == [0, 0, 0, 1, 3, 5, 7, 9, 10])
        value.animate(to: 0, animation: .init(startTime: 0, animation: .linear(duration: 0.5).delay(0.5).speed(0.5)))
        #expect(value.progressToEnd(sampling: 0.2) == [10, 10, 10, 10, 10, 10, 8, 6, 4, 2, 0, 0])
    }

    @Test
    func peeksValues() {
        // var value = AnimatedValue(value: TestValue(0))
        // value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 1)))
        // let peeked = value.peekFutureValues(stride(from: 0.0, through: 1.5, by: 0.2))
        // #expect(peeked == [0, 2, 4, 6, 8, 10, 10, 10])
        // #expect(value.presentation == 0)
        // #expect(value.isAnimating == true)
    }
}

extension AnimatedValue {
    mutating func progressToEnd(sampling: Double) -> [Value] {
        var time = 0.0
        var values: [Value] = []
        values.append(presentation)

        while isAnimating {
            time += sampling
            self.progressToTime(time)
            values.append(presentation)
        }

        return values
    }
}

struct TestValue: AnimatableVectorConvertible, ExpressibleByIntegerLiteral {
    var value: Int

    init(_ value: Int) {
        self.value = value
    }

    init(integerLiteral value: Int) {
        self.value = value
    }

    var animatableVector: AnimatableVector {
        Float(value).animatableVector
    }

    init(_ animatableVector: AnimatableVector) {
        self.value = Int(Float(animatableVector))
    }
}

extension TestValue: Equatable, CustomStringConvertible {
    static func == (lhs: TestValue, rhs: TestValue) -> Bool {
        lhs.value == rhs.value
    }

    var description: String {
        value.description
    }
}
