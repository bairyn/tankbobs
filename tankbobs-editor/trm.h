#ifndef TRM_H
#define TRM_H

bool trm_open(const char *filename);
bool trm_save(const char *filename);
void trm_select(int x, int y);
void trm_newPlayerSpawnPoint(int x, int y);
void trm_newPowerupSpawnPoint(int x, int y);
void trm_newTeleporter(int x, int y);
void trm_newWall(int xs, int ys, int xe, int ye);
void trm_keypress(int key, bool initial);
void trm_keyrelease(int key);

#define NOVALUEDOUBLE  1.5e307

#endif
