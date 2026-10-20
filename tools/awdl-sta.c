/* awdl-sta: add or remove an AWDL peer as an associated, HT-capable station on
 * an AP vif, so the Wi-Fi firmware has a station entry for it (needed for a
 * hardware RX Block Ack). usage: awdl-sta add|del IFACE MAC [AID] */
#include <errno.h>
#include <net/if.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <linux/nl80211.h>
#include <netlink/genl/ctrl.h>
#include <netlink/genl/genl.h>
#include <netlink/netlink.h>

static int ack_err;

static int on_err(struct sockaddr_nl *nla, struct nlmsgerr *e, void *arg)
{
	(void)nla; (void)arg;
	ack_err = e->error;
	return NL_STOP;
}

static int on_ack(struct nl_msg *m, void *arg)
{
	(void)m; (void)arg;
	ack_err = 0;
	return NL_STOP;
}

int main(int argc, char **argv)
{
	unsigned int m[6];
	unsigned char mac[6];
	int add, ifidx, fam, i, aid;
	struct nl_sock *sk;
	struct nl_msg *msg;
	struct nl_cb *cb;

	if (argc < 4 || (strcmp(argv[1], "add") && strcmp(argv[1], "del")) ||
	    sscanf(argv[3], "%x:%x:%x:%x:%x:%x", &m[0], &m[1], &m[2], &m[3], &m[4], &m[5]) != 6) {
		fprintf(stderr, "usage: %s add|del IFACE MAC [AID]\n", argv[0]);
		return 2;
	}
	add = !strcmp(argv[1], "add");
	for (i = 0; i < 6; i++)
		mac[i] = m[i];
	aid = argc > 4 ? atoi(argv[4]) : 1;
	ifidx = if_nametoindex(argv[2]);
	if (!ifidx) {
		perror(argv[2]);
		return 1;
	}

	sk = nl_socket_alloc();
	if (!sk || genl_connect(sk))
		return 1;
	fam = genl_ctrl_resolve(sk, "nl80211");
	if (fam < 0)
		return 1;

	msg = nlmsg_alloc();
	genlmsg_put(msg, 0, 0, fam, 0, 0,
		    add ? NL80211_CMD_NEW_STATION : NL80211_CMD_DEL_STATION, 0);
	nla_put_u32(msg, NL80211_ATTR_IFINDEX, ifidx);
	nla_put(msg, NL80211_ATTR_MAC, 6, mac);
	if (add) {
		/* 5 GHz OFDM rates, 500 kb/s units */
		static const unsigned char rates[] = { 12, 18, 24, 36, 48, 72, 96, 108 };
		/* struct ieee80211_ht_cap: cap_info SM-PS disabled, SGI20, RX STBC 1;
		 * A-MPDU 64 KiB; MCS 0-15 */
		unsigned char ht[26] = { 0 };
		struct nl80211_sta_flag_update fl;

		ht[0] = 0x2c; ht[1] = 0x01;
		ht[2] = 0x03;
		ht[3] = 0xff; ht[4] = 0xff;
		nla_put(msg, NL80211_ATTR_STA_SUPPORTED_RATES, sizeof(rates), rates);
		nla_put_u16(msg, NL80211_ATTR_STA_AID, aid);
		nla_put_u16(msg, NL80211_ATTR_STA_LISTEN_INTERVAL, 10);
		nla_put_u16(msg, NL80211_ATTR_STA_CAPABILITY, 0x0001);
		nla_put(msg, NL80211_ATTR_HT_CAPABILITY, sizeof(ht), ht);
		fl.mask = fl.set = (1 << NL80211_STA_FLAG_AUTHORIZED) |
				   (1 << NL80211_STA_FLAG_AUTHENTICATED) |
				   (1 << NL80211_STA_FLAG_ASSOCIATED) |
				   (1 << NL80211_STA_FLAG_WME);
		nla_put(msg, NL80211_ATTR_STA_FLAGS2, sizeof(fl), &fl);
	}

	cb = nl_cb_alloc(NL_CB_DEFAULT);
	nl_cb_err(cb, NL_CB_CUSTOM, on_err, NULL);
	nl_cb_set(cb, NL_CB_ACK, NL_CB_CUSTOM, on_ack, NULL);
	ack_err = 1;
	if (nl_send_auto(sk, msg) < 0)
		return 1;
	while (ack_err > 0)
		nl_recvmsgs(sk, cb);
	if (ack_err) {
		fprintf(stderr, "%s %s: %s\n", argv[1], argv[3], strerror(-ack_err));
		return 1;
	}
	return 0;
}
