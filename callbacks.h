#ifndef callbacks_h
#define callbacks_h

#include <libircclient.h>
#include <libirc_rfcnumeric.h>

void event_connect(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
void event_generic(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
void event_numeric(irc_session_t *session, unsigned int event, const char *origin, const char **params, unsigned int count);

#endif
