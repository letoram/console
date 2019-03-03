#include <arcan_shmif.h>

static void draw_frame(struct arcan_shmif_cont* C, size_t ts)
{
	float ss = 255.0 / C->w;
	float st = 255.0 / C->h;

	for (size_t y = 0; y < C->h; y++)
		for (size_t x = 0; x < C->w; x++){
			uint8_t r = ts + ss * x;
			uint8_t g = ts + st * y;
			size_t pos = y * C->pitch + x;
			C->vidp[pos] = SHMIF_RGBA(r, g, 0, 0xff);
		}
}

int main(int argc, char** argv)
{
/* can be used with if (arg_lookup(args, "key", occurence, &str_result) */
	struct arg_arr* args;

/* extended version that allows us to specify title/ident/uuid */
	struct arcan_shmif_cont conn =
		arcan_shmif_open_ext(SHMIF_ACQUIRE_FATALFAIL, &args,
			(struct shmif_open_ext){.type = SEGID_MEDIA, .title = "demo"},
			sizeof(struct shmif_open_ext)
		);

/* don't really need now, but good to know about */
	struct arcan_shmif_initial* cfg;
	arcan_shmif_initial(&conn, &cfg);

	size_t ts = 0;
	for (;;){
		draw_frame(&conn, ts++);
		arcan_shmif_signal(&conn, SHMIF_SIGVID);
	}

	return EXIT_SUCCESS;
}
