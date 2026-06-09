/* Automation Studio generated header file */
/* Do not edit ! */
/* UserLog 2.0.3 */

#ifndef _USERLOG_
#define _USERLOG_
#ifdef __cplusplus
extern "C" 
{
#endif
#ifndef _UserLog_VERSION
#define _UserLog_VERSION 2.0.3
#endif

#include <bur/plctypes.h>

#ifndef _BUR_PUBLIC
#define _BUR_PUBLIC
#endif
#ifdef _SG3
		#include "ArEventLog.h"
		#include "sys_lib.h"
		#include "astime.h"
#endif
#ifdef _SG4
		#include "ArEventLog.h"
		#include "sys_lib.h"
		#include "astime.h"
#endif
#ifdef _SGC
		#include "ArEventLog.h"
		#include "sys_lib.h"
		#include "astime.h"
#endif


/* Datatypes and datatypes of function blocks */
typedef enum UserLogSeverityEnum
{	USERLOG_SEVERITY_DEBUG = -1,
	USERLOG_SEVERITY_SUCCESS,
	USERLOG_SEVERITY_INFORMATION,
	USERLOG_SEVERITY_WARNING,
	USERLOG_SEVERITY_ERROR,
	USERLOG_SEVERITY_CRITICAL
} UserLogSeverityEnum;

typedef struct UserLogFormatType
{	plcbit b[6];
	double f[6];
	signed long i[6];
	plcstring s[6][81];
} UserLogFormatType;



/* Prototyping of functions and function blocks */
_BUR_PUBLIC unsigned long UserLogBasic(signed long Severity, unsigned short Code, plcstring* Message);
_BUR_PUBLIC unsigned long UserLogAdvanced(signed long Severity, unsigned short Code, plcstring* Message, struct UserLogFormatType* Values);
_BUR_PUBLIC unsigned long UserLogCustom(plcstring* Logbook, signed long Severity, unsigned short Facility, unsigned short Code, ArEventLogRecordIDType Origin, plcstring* Object, plcstring* Message, struct UserLogFormatType* Values);
_BUR_PUBLIC unsigned long UserLogEventText(plcstring* Logbook, signed long Event, ArEventLogRecordIDType Origin, plcstring* Object, plcstring* Message, struct UserLogFormatType* Values);
_BUR_PUBLIC signed long UserLogCreate(plcstring* Name, unsigned long Size);
_BUR_PUBLIC signed long UserLogSetSeverityLevel(signed long Level);
_BUR_PUBLIC unsigned char UserLogGetSeverity(signed long Event);
_BUR_PUBLIC unsigned short UserLogGetFacility(signed long Event);
_BUR_PUBLIC unsigned short UserLogGetCode(signed long Event);


/* Constants */
#ifdef _REPLACE_CONST
 #define USERLOG_EXAMPLE_TEXT_ID 1632259616
 #define USERLOG_FORMAT_LENGTH 80U
 #define USERLOG_FORMAT_INDEX 5U
 #define USERLOG_ERROR_CREATE (-515234012)
 #define USERLOG_ERROR_WRITE (-515234022)
 #define USERLOG_ERROR_IDENT (-515234032)
 #define USERLOG_FACILITY 10U
 #define USERLOG_MESSAGE_LENGTH 120U
#else
 _GLOBAL_CONST signed long USERLOG_EXAMPLE_TEXT_ID;
 _GLOBAL_CONST unsigned char USERLOG_FORMAT_LENGTH;
 _GLOBAL_CONST unsigned char USERLOG_FORMAT_INDEX;
 _GLOBAL_CONST signed long USERLOG_ERROR_CREATE;
 _GLOBAL_CONST signed long USERLOG_ERROR_WRITE;
 _GLOBAL_CONST signed long USERLOG_ERROR_IDENT;
 _GLOBAL_CONST unsigned short USERLOG_FACILITY;
 _GLOBAL_CONST unsigned long USERLOG_MESSAGE_LENGTH;
#endif




#ifdef __cplusplus
};
#endif
#endif /* _USERLOG_ */

