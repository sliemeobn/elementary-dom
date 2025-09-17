import Testing

@testable import ElementaryDOM

@Suite
struct AnimatedValueTests {
    @Test
    func animatesLinearly() {
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
    func peeksValues() {
        var value = AnimatedValue(value: TestValue(0))
        value.animate(to: 10, animation: .init(startTime: 0, animation: .linear(duration: 1)))
        let peeked = value.peekFutureValues(stride(from: 0.0, through: 1.5, by: 0.2))
        #expect(peeked == [0, 2, 4, 6, 8, 10, 10, 10])
        #expect(value.presentation == 0)
        #expect(value.isAnimating == true)
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
