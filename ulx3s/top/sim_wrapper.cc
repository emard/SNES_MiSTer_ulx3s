#include "sim_out.cc"
#include <iostream>
#include <fstream>

int main() {
  cxxrtl_design::p_top top;
  auto last_hs = top.p_HSYNC.curr;
  auto last_vs = top.p_VSYNC.curr;

  int cycle = 0;
  std::ofstream frame("./snes_frames/snes_frame0.csv");
  int frame_count = 0;
  while (1) {
    top.p_clk__sys = value<1> {1u};
    int d0 = top.step();
    top.p_clk__sys = value<1> {0u};
    int d1 = top.step();
    if ((cycle % 2) == 0) {
      frame << top.p_R.curr << "|" << top.p_G.curr << "|" << top.p_B.curr << ",";
    }
    if (last_hs && !top.p_HSYNC.curr) {
      std::cerr << "hsync" << std::endl;
      frame << std::endl;
    }
    if (last_vs && !top.p_VSYNC.curr) {
      std::cerr << "vsync" << std::endl;
      frame << std::endl;
      frame.close();
      ++frame_count;
      frame.open("./snes_frames/snes_frame" + std::to_string(frame_count) + ".csv");
    }
    last_hs = top.p_HSYNC.curr;
    last_vs = top.p_VSYNC.curr;
    ++cycle;
    if ((cycle % 100000) == 0)
      std::cerr << "cycle " << cycle << std::endl;
  }
}
