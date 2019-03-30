#pragma libcall XProtocolBase XProtocolCleanup 1e 801
#pragma libcall XProtocolBase XProtocolSetup 24 801
#pragma libcall XProtocolBase XProtocolSend 2a 801
#pragma libcall XProtocolBase XProtocolReceive 30 801

long XProtocolCleanup(struct XPR_IO *);
long XProtocolSetup(struct XPR_IO *);
long XProtocolSend(struct XPR_IO *);
long XProtocolReceive(struct XPR_IO *);
