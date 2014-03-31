#ifndef error_h
#define error_h

void irc_error(irc_session_t* irc_session, int fatal);
void error(int fatal, char* format, ...);

#endif
