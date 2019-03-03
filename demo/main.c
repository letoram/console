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

static bool handle_input(struct arcan_shmif_cont* C, struct arcan_event* ev)
{
	return (
		ev->io.kind == EVENT_IO_BUTTON &&
		ev->io.devkind == EVENT_IDEVKIND_KEYBOARD &&
		ev->io.datatype == EVENT_IDATATYPE_TRANSLATED &&
		ev->io.input.translated.keysym == 108 &&
		ev->io.input.translated.active
	);
}

static bool handle_target(struct arcan_shmif_cont* C, struct arcan_event* ev)
{
	return false;
}

static void event_loop(struct arcan_shmif_cont* C)
{
	struct arcan_event ev;
	size_t step = 0;

/* send an initial frame so that there is a visible window to provide input */
	draw_frame(C, step++);
	arcan_shmif_signal(C, SHMIF_SIGVID);

	while(arcan_shmif_wait(C, &ev)){
		bool dirty = false;
		if (ev.category == EVENT_IO)
			dirty |= handle_input(C, &ev);
		else if (ev.category == EVENT_TARGET)
			dirty |= handle_target(C, &ev);

			if (!dirty)
				continue;

		draw_frame(C, step++);
		arcan_shmif_signal(C, SHMIF_SIGVID);
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

	event_loop(&conn);

	return EXIT_SUCCESS;
}
