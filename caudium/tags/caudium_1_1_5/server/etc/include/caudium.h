// $Id$
#ifndef _CAUDIUM_H_
#define _CAUDIUM_H_
#include <config.h>
#define HOST_TO_IP 'H'
#define IP_TO_HOST 'I'
#endif

#define perror	roxen_perror
#if constant(Stdio.Stat)
#define file_stat caudium_fstat
#endif
#define CONFIGURATION_FILE_LEVEL 6

#ifdef DEBUG_LEVEL
#if DEBUG_LEVEL > 7
#ifndef HOST_NAME_DEBUG
# define HOST_NAME_DEBUG
#endif
#endif
#endif /* DEBUG_LEVEL is not defined from install */

