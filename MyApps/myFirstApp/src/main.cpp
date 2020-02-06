#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/sysinfo.h>

#include "main.h"
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
const char *rp_app_desc(void)
{
    return (const char *)"Template application.\n";
}


int rp_app_init(void)
{
    fprintf(stderr, "Loading template application\n");
    return 0;
}


int rp_app_exit(void)
{
    fprintf(stderr, "Unloading template application\n");
    return 0;
}


int rp_set_params(rp_app_params_t *p, int len)
{
    return 0;
}


int rp_get_params(rp_app_params_t **p)
{
    return 0;
}


int rp_get_signals(float ***s, int *sig_num, int *sig_len)
{
    return 0;
}


void UpdateSignals(void){}


void UpdateParams(void){}

CBooleanParameter ledState("LED_STATE", CBaseParameter::RW, false, 0);

void print_debug(const char *sz)
{
	FILE *file = fopen ("/root/omer.debug", "w+");
	fprintf (file, "%s\n");
	fclose (file);
}

void OnNewParams(void) {
	ledState.Update();
	print_debug("led state updated"\n");
//	printf("led state updated"\n");
	if (ledState.Value()) {
		rp_DpinSetState(RP_LED0, RP_HIGH);
	}
	else {
		rp_DpinSetState(RP_LED0, RP_LOW);
	}
}


void OnNewSignals(void){}


void PostUpdateSignals(void){}
