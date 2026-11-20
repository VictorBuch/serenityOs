import { View, div } from "gpui-kit";
import { hc, terminals, focused, home, run, props, closeOverlay, notify } from "herdr";

export default class JjuiFloat extends View {
  init(_props, cx) {
    const cwd = focused()?.cwd ?? home();
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["run", "--bg", "--json", "--rm", "--no-parent", "--cwd", cwd, "--", "env", "TERM=xterm-256color", "COLORTERM=truecolor", "jjui"]);
        const address = JSON.parse(r.stdout).address;
        for (let i = 0; i < 40 && !terminals().some((t) => t.address === address); i++) await cx.sleep(50);
        run("terminal.peek", { terminal: address });
      } catch (e) {
        notify({ title: "jjui", body: String(e), level: "error" });
      }
      closeOverlay(props()?.overlay);
    });
  }

  render() {
    return div();
  }
}
