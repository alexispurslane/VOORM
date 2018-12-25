#include<ncurses.h>

void init_color_pairs() {
  start_color();
  init_pair(1, COLOR_RED, COLOR_WHITE);
  init_pair(2, COLOR_WHITE, COLOR_GREEN);
}

void draw_border(int p) {
  attrset(COLOR_PAIR(p));
  border('*', '*', '~', '~',  '*', '*', '*', '*');
}

void draw_message(int p) {
  attrset(COLOR_PAIR(p));
  mvprintw(1, 1, "Merry Christmas!");
}

int main() {
  initscr();
  setlocale(0, "");
  raw();
  noecho();

  init_color_pairs();

  draw_border(1);
  draw_message(2);

  refresh();
  int c = getch();
}
