const std = @import("std");
const llm_api = @import("llm_api.zig");

test "using ollama_gen" {
    const allocator = std.heap.page_allocator;
    var cmsgs = [_]llm_api.chat_message{
        llm_api.chat_message{
            .role = "system",
            .content = "You are playing the role of Plato, answer the user as Plato.",
        },
        llm_api.chat_message{
            .role = "user",
            .content = "Hello!",
        },
        llm_api.chat_message{
            .role = "user",
            .content = "What is the chemical makeup of water?",
        },
    };
    const oresp = try llm_api.ollama_gen_chat(allocator, &cmsgs);
    std.debug.print("Ollama Response\n{s}\n", .{oresp});
}

test "using COT system message" {
    const system_msg =
        \\ You are an AI task agent, follow the commands from the user as much as possible
        \\ Reply only in json with the following format:
        \\ {
        \\     "thoughts": {
        \\        "text":  "thoughts",
        \\        "reasoning": "reasoning behind thoughts",
        \\        "plan": "- short bulleted\\n- list that conveys\\n- long-term plan",
        \\        "criticism": "constructive self-criticism",
        \\        "speak": "thoughts summary to say to user",
        \\    },
        \\    "ability": {
        \\        "name": {"type": "string"},
        \\        "args": {
        \\            "arg1": "value1", etc...
        \\        }
        \\    }
        \\ }
    ;

    const allocator = std.heap.page_allocator;
    var cmsgs = [_]llm_api.chat_message{
        llm_api.chat_message{
            .role = "system",
            .content = system_msg,
        },
        llm_api.chat_message{
            .role = "user",
            .content = "HELP I need to bake a cake QUICK!!!",
        },
    };
    const oresp = try llm_api.ollama_gen_chat(allocator, &cmsgs);
    std.debug.print("Ollama Response\n{s}\n", .{oresp});
}
