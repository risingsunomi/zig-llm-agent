// LLM API
// Defines the API interface for various LLMs
// Current focus is ollama local LLM

const std = @import("std");
const json = @import("json");

// ollama_gen_resp
// response from generate api
pub const ollama_gen_resp = struct {
    model: []const u8,
    created_at: []const u8,
    response: []const u8,
    done: bool,
    context: []const u32,
    total_duration: u64,
    load_duration: u64,
    prompt_eval_count: u32,
    prompt_eval_duration: u64,
    eval_count: u32,
    eval_duration: u64,
};

// ollama_chat_resp
// response from chat api
pub const ollama_chat_resp = struct {
    model: []const u8,
    created_at: []const u8,
    message: struct {
        role: []const u8,
        content: []const u8,
    },
    done: bool,
    total_duration: u64,
    // load_duration: u64,
    // prompt_eval_count: u32,
    // prompt_eval_duration: u64,
    // eval_count: u32,
    // eval_duration: u64,
};

// chat_message
pub const chat_message = struct {
    role: []const u8,
    content: []const u8,
};

// ollama chat req
pub const ollama_chat_req = struct {
    model: []const u8,
    messages: []chat_message,
    stream: bool,
};

// ollama chat req with tools
const ollama_chat_req_tool = struct {
    model: []const u8,
    messages: []chat_message,
    stream: bool,
    tools: []struct {
        type: []const u8,
        function: struct {
            name: []const u8,
            description: []const u8,
            parameters: struct {
                type: []const u8,
                properties: struct {},
                required: []const []const u8,
            },
        },
    },
};

// ollama_gen_chat
// reaches out to ollama generate chat api with prompt
// returns llm response
pub fn ollama_gen_chat(allocator: std.mem.Allocator, messages: []chat_message) anyerror![]const u8 {

    // load messages into array for chat messages in ollama chat req struct
    var oc_req_msgs = std.ArrayList(chat_message).init(allocator);
    defer oc_req_msgs.deinit();

    for (messages) |message| {
        // create a chat_message struct
        try oc_req_msgs.append(message);
    }

    // build chat req struct
    const oc_req: ollama_chat_req = .{
        .model = "llama3.1",
        .stream = false,
        .messages = oc_req_msgs.items,
    };

    // convert request to a json string
    // will cause error if arraylist is passed and not arraylist.items
    var json_oc_req = std.ArrayList(u8).init(allocator);
    defer json_oc_req.deinit();
    try std.json.stringify(
        oc_req,
        .{},
        json_oc_req.writer(),
    );

    // fetch to ollama generate api
    // setup http client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // setup fetch
    const uri = try std.Uri.parse("http://192.168.0.5/api/chat");
    const fetch_loc: std.http.Client.FetchOptions.Location = .{
        .uri = uri,
    };
    var fetch_dynamic_list = std.ArrayList(u8).init(allocator);
    defer fetch_dynamic_list.deinit();

    var server_header_buf: [4096]u8 = undefined;
    const resp: std.http.Client.FetchResult = try client.fetch(.{
        .payload = json_oc_req.items,
        .method = .POST,
        .server_header_buffer = &server_header_buf,
        .location = fetch_loc,
        .headers = .{
            .content_type = .{ .override = "application/json" },
        },
        .response_storage = .{ .dynamic = &fetch_dynamic_list },
    });

    // get reponse if status is ok
    if (resp.status == std.http.Status.ok) {
        const ollama_response = try allocator.dupe(u8, fetch_dynamic_list.items);

        // Parse JSON
        const json_parse = try std.json.parseFromSlice(
            ollama_chat_resp,
            allocator,
            ollama_response,
            .{ .ignore_unknown_fields = true },
        );
        defer json_parse.deinit();

        const parsed_oresp = json_parse.value;

        // Duplicate the response string to ensure it outlives this function
        const response_copy = try allocator.dupe(u8, parsed_oresp.message.content);
        allocator.free(ollama_response);

        return response_copy;
    } else {
        std.debug.print("status not ok: {any}", .{resp.status});
        return error.HttpStatusNotOk;
    }
}
