import ElementaryUI
import Testing

@Suite
struct BindingTests {
    @Test
    func createsACustomBinding() {
        var data = 0

        let binding = Binding(get: { data }, set: { data = $0 })

        #expect(binding.wrappedValue == 0)
        binding.wrappedValue = 42
        #expect(binding.wrappedValue == 42)
        #expect(data == 42)
    }

    @Test
    func createsAMacroBinding() {
        var data = 0

        let binding = #Binding(data)

        #expect(binding.wrappedValue == 0)
        binding.wrappedValue = 42
        #expect(binding.wrappedValue == 42)
        #expect(data == 42)
    }
}
