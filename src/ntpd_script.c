#include <err.h>
#include <stdlib.h>
#include <stdio.h>

static const char *getenv_default(const char *key, const char *default_value)
{
    const char *result = getenv(key);
    return result != NULL ? result : default_value;
}

int main(int argc, char *argv[])
{
    if (argc < 2)
        errx(EXIT_FAILURE, "Expecting on argument from ntpd.");

    printf("ntpd_script: %s,%s,%s,%s,%s\n",
           argv[1],
           getenv_default("freq_drift_ppm", "0"),
           getenv_default("offset", "0.000000"),
           getenv_default("stratum", "16"),
           getenv_default("poll_interval", "0")
           );

    exit(EXIT_SUCCESS);
}
