#ifndef _arpa_inet_h
#define	_arpa_inet_h

#include <sys/socket.h>
#include <netinet/in.h>

int htons(int);
long htonl(long);
int ntohs(int);
long ntohl(long);

in_addr_t inet_addr(const char *cp);
in_addr_t inet_lnaof(struct in_addr in);
struct in_addr inet_makeaddr(in_addr_t net, in_addr_t lna);
in_addr_t inet_netof(struct in_addr in);
in_addr_t inet_network(const char *cp);
char *inet_ntoa(struct in_addr in);

#endif
