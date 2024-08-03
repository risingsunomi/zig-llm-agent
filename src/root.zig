const std = @import("std");
const llm_api = @import("llm_api");

test "using ollama_gen" {
    // use general purpose allocator
    const allocator = std.heap.page_allocator;
    const cmsgs = [][]u8{ "Hello!", "Can you explain how to use Zig for robotics?" };
    const oresp = try llm_api.ollama_gen_chat(allocator, cmsgs);
    std.debug.print("Ollama Response\n{s}\n", .{oresp});
}
