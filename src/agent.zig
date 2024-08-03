// LLM or AI Agent
// creating an agent event loop

const std = @import("std");

fn run_agent(user_task: []const u8) anyerror!void {
    var allocator = std.heap.page_allocator;
    
    const ollama_params = try std.fmt.allocPrint(
        allocator,
        "{{ \"model\": \"llama3\", \"prompt\": \"{s}\", \"stream\": false }}",
        .{user_task},
    );
    defer allocator.free(ollama_params);
}
