#ifndef TRM_H
#define TRM_H

int  trm_isSelected(void *e);
void trm_setSelected(void *e);
void trm_clearAndSetSelected(void *e);
bool trm_open(const char *filename, bool import);
bool trm_save(const char *filename);
void trm_select(int x, int y);
void trm_newPlayerSpawnPoint(int x, int y);
void trm_newPowerupSpawnPoint(int x, int y);
void trm_newTeleporter(int x, int y);
void trm_newWall(int xs, int ys, int xe, int ye);
int  trm_keypress(int key, bool initial, QKeyEvent *e);
int  trm_keyrelease(int key, QKeyEvent *e);
void trm_modifyAttempted();

//#define TEMAXBUF 1024
#define TEMAXBUF 100000
#define GRIDSIZE 100.0
#define GRIDLINES 4  // approximate number of grid lines drawn on each side
#define ZOOMFACTOR 0.02  // 2% per pixel
#define ZOOMQUADFACTOR 0.75
#define MINZOOM 0.125
#define MAXZOOM 1.2
#define MINSCROLL -GRIDSIZE * GRIDLINES
#define MAXSCROLL  GRIDSIZE * GRIDLINES

#define ZOOM ((zoom) > (1.0) ? (zoom) : (1.0))

#endif
