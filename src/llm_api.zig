// LLM API
// Defines the API interface for various LLMs
// Current focus is ollama local LLM

const std = @import("std");

// ollama_chat_resp
pub const ollama_chat_resp = struct {
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

// ollama_gen_chat
// reaches out to ollama generate chat api with prompt
// returns llm response
pub fn ollama_gen_chat(allocator: std.mem.Allocator, messages: [][]const u8) anyerror![]const u8 {
    // setup http client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // setup fetch
    var buf: [4096]u8 = undefined;
    const uri = try std.Uri.parse("http://192.168.0.5/api/chat");
    const fetch_loc: std.http.Client.FetchOptions.Location = .{ .uri = uri };
    var fetch_dynamic_list = std.ArrayList(u8).init(allocator);
    defer fetch_dynamic_list.deinit();

    const oc_req = ollama_chat_req{ .model = "llama3.1", .stream = false };
    for (messages) |message| {
        // create a chat_message struct
        const cmsg = chat_message{ .content = message, .role = "user" };

        // turn the array to a slice to append
        oc_req.messages = &[0]chat_message;
        oc_req.messages = oc_req.messages ++ cmsg;
    }

    std.debug.print("oc_req:\n{s}\n", .{oc_req});

    // fetch to ollama generate api
    const resp: std.http.Client.FetchResult = try client.fetch(.{
        .payload = oc_req,
        .method = .POST,
        .server_header_buffer = &buf,
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
            .{},
        );
        defer json_parse.deinit();

        const parsed_oresp = json_parse.value;

        // Duplicate the response string to ensure it outlives this function
        const response_copy = try allocator.dupe(u8, parsed_oresp.response);
        allocator.free(ollama_response);

        std.debug.print("Ollama Response\n{s}\n", .{response_copy});
        return response_copy;
    } else {
        std.debug.print("status not ok: {any}", .{resp.status});
        return error.HttpStatusNotOk;
    }
}
