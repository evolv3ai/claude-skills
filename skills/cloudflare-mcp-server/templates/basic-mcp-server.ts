/**
 * Basic MCP Server (No Authentication)
 *
 * A simple Model Context Protocol server with basic tools.
 * Demonstrates the core McpAgent pattern without authentication.
 *
 * Perfect for: Internal tools, development, public APIs
 *
 * Based on: https://github.com/cloudflare/ai/tree/main/demos/remote-mcp-authless
 */

import { McpAgent } from "agents/mcp";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

type Env = {
  // Add your environment bindings here
  // Example: MY_KV: KVNamespace;
};

/**
 * MyMCP extends McpAgent to create a stateless MCP server
 */
export class MyMCP extends McpAgent<Env> {
  server = new McpServer({
    name: "My MCP Server",
    version: "1.0.0",
  });

  /**
   * Initialize tools, resources, and prompts
   * Called automatically by McpAgent base class
   */
  async init() {
    // Simple calculation tool
    this.server.tool(
      "add",
      "Add two numbers together",
      {
        a: z.number().describe("First number"),
        b: z.number().describe("Second number"),
      },
      async ({ a, b }) => ({
        content: [
          {
            type: "text",
            text: `The sum of ${a} + ${b} = ${a + b}`,
          },
        ],
      })
    );

    // Calculator tool with operations
    this.server.tool(
      "calculate",
      "Perform basic arithmetic operations",
      {
        operation: z
          .enum(["add", "subtract", "multiply", "divide"])
          .describe("The arithmetic operation to perform"),
        a: z.number().describe("First operand"),
        b: z.number().describe("Second operand"),
      },
      async ({ operation, a, b }) => {
        let result: number;

        switch (operation) {
          case "add":
            result = a + b;
            break;
          case "subtract":
            result = a - b;
            break;
          case "multiply":
            result = a * b;
            break;
          case "divide":
            if (b === 0) {
              return {
                content: [
                  {
                    type: "text",
                    text: "Error: Division by zero is not allowed",
                  },
                ],
                isError: true,
              };
            }
            result = a / b;
            break;
        }

        return {
          content: [
            {
              type: "text",
              text: `Result: ${a} ${operation} ${b} = ${result}`,
            },
          ],
        };
      }
    );

    // Example resource (optional)
    this.server.resource({
      uri: "about://server",
      name: "About this server",
      description: "Information about this MCP server",
      mimeType: "text/plain",
    }, async () => ({
      contents: [{
        uri: "about://server",
        mimeType: "text/plain",
        text: "This is a basic MCP server running on Cloudflare Workers"
      }]
    }));
  }
}

/**
 * Worker fetch handler
 * Supports both SSE and Streamable HTTP transports
 */
export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    const { pathname } = new URL(request.url);

    // SSE transport (legacy, but widely supported)
    if (pathname === "/sse" || pathname.startsWith("/sse/")) {
      return MyMCP.serveSSE("/sse").fetch(request, env, ctx);
    }

    // Streamable HTTP transport (2025 standard)
    if (pathname === "/mcp" || pathname.startsWith("/mcp/")) {
      return MyMCP.serve("/mcp").fetch(request, env, ctx);
    }

    // Health check endpoint
    if (pathname === "/") {
      return new Response(
        JSON.stringify({
          name: "My MCP Server",
          version: "1.0.0",
          transports: ["/sse", "/mcp"],
        }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    return new Response("Not Found", { status: 404 });
  },
};
