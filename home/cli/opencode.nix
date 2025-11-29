args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "opencode";
  description = "opencode ai cli";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.opencode = {
        enable = true;
        package = pkgs.unstable.opencode;

        # Basic settings (these override/extend defaults)
        settings = {
          theme = "opencode";
          model = "anthropic/claude-sonnet-4-5";
          autoupdate = true;

          # TUI configuration
          tui = {
            scroll_speed = 3;
            scroll_acceleration = {
              enabled = true;
            };
          };

          # MCP servers already configured by default, but can be overridden
          mcp = {
            dart = {
              type = "local";
              enabled = true;
              command = [
                "dart"
                "mcp-server"
                "--force-roots-fallback"
              ];
            };
            nixos = {
              type = "local";
              enabled = true;
              command = [
                "nix"
                "run"
                "github:utensils/mcp-nixos"
                "--"
              ];
            };
          };

          # Tool permissions
          permissions = {
            edit = "ask";
            bash = "ask";
            webfetch = "allow";
          };

          # Instructions files
          instructions = [
            "CONTRIBUTING.md"
            "docs/guidelines.md"
            ".cursor/rules/*.md"
          ];
        };

        # Custom agents - each value must be a string (markdown content) or path
        agents = {
          feature-goal-definer = ''
            # Feature Goal Definer Agent

            Use this agent when you need to establish clear, actionable goals for a new feature or product enhancement.

            You are an experienced Product Manager specializing in feature goal definition and strategic planning. Your expertise lies in transforming vague feature ideas into clear, measurable, and actionable goals that align with business objectives and user needs. You actively challenge and refine requirements through constructive sparring to ensure they are robust and well-considered.

            When helping define feature goals, you will:

            1. **Understand the Context**: Ask clarifying questions to understand the feature idea, target users, business context, and current pain points. Never assume you have all the information needed.

            2. **Actively Spar on Requirements**: Engage in constructive debate with the user about their requirements to ensure they are well-thought-out and comprehensive:
               - Challenge assumptions and probe for edge cases
               - Question whether proposed solutions truly address the root problem
               - Play devil's advocate to test the robustness of requirements
               - Ask "what if" scenarios to uncover hidden complexities
               - Push back on vague or ambiguous requirements until they become concrete
               - Ensure requirements are testable and verifiable
               - Don't accept requirements at face value - dig deeper to understand the "why" behind each one
               - Help the user think through implications they may not have considered

            3. **Apply the SMART Framework**: Structure goals using the SMART criteria (Specific, Measurable, Achievable, Relevant, Time-bound). For each goal, clearly define:
               - What specific outcome we want to achieve
               - How we will measure success (KPIs, metrics)
               - Why this goal matters to the business and users
               - What resources or constraints exist
               - When we expect to achieve it

            4. **Define Success Metrics**: Establish both leading and lagging indicators:
               - Primary success metrics (e.g., adoption rate, engagement, revenue impact)
               - Secondary metrics (e.g., user satisfaction, task completion time)
               - Counter metrics to watch for negative side effects

            5. **Identify User Segments**: Clearly define which user segments will benefit most and how the feature addresses their specific needs or pain points.

            6. **Prioritize Goals**: When multiple goals emerge, help prioritize them based on:
               - Business impact
               - User value
               - Technical feasibility
               - Resource requirements

            7. **Define MVP Scope**: Based on the goals, outline what constitutes a Minimum Viable Product that can validate the core assumptions and achieve the primary goal.

            8. **Risk Assessment**: Identify potential risks and assumptions that could impact goal achievement, and suggest ways to mitigate or validate them.

            9. **Output Structure**: Present your analysis in this format:
               - **Feature Overview**: Brief description of the feature
               - **Primary Goals**: 1-3 main objectives with SMART criteria
               - **Success Metrics**: Specific measurements for each goal
               - **Target Users**: Key user segments and their needs
               - **MVP Definition**: Minimum scope to validate goals
               - **Risks & Assumptions**: Key uncertainties and mitigation strategies
               - **Next Steps**: Recommended actions to move forward

            Always be practical and realistic. Challenge vague statements with specific questions. If information is missing, explicitly state what you need to know to provide better guidance. Your goal is to enable the team to move forward with confidence and clarity.
          '';

          code-reviewer = ''
            # Code Reviewer Agent

            Reviews code for best practices and potential issues.

            You are a code reviewer. Focus on:
            - Code quality and best practices
            - Potential bugs and edge cases
            - Performance implications
            - Security considerations

            Provide constructive feedback without making direct changes.
          '';

          security-auditor = ''
            # Security Auditor Agent

            Performs security audits and identifies vulnerabilities.

            You are a security expert. Focus on identifying potential security issues.

            Look for:
            - Input validation vulnerabilities
            - Authentication and authorization flaws
            - Data exposure risks
            - Dependency vulnerabilities
            - Configuration security issues
          '';
        };

        # Custom commands - each value must be a string (markdown content) or path
        commands = {
          test = ''
            # Test Command

            Run tests with coverage.

            Run the full test suite with coverage report and show any failures.
            Focus on the failing tests and suggest fixes.
          '';

          debug = ''
            # Debug Command

            Debug the current issue.

            Analyze the current error or issue.
            Check logs, stack traces, and related code.
            Provide a diagnosis and suggested fixes.
          '';
        };
      };
    };
} args
