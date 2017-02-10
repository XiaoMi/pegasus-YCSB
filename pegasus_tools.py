#!/usr/bin/python

from ConfigParser import ConfigParser
from smtplib import SMTP
from os.path import basename
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate
from email import Encoders

# this python script is used to merge the result of ycsb-testing running on the 
# server : c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj c4-hadoop-tst-st75.bj

#file name = prefix.result_servername
def merge_result(servers, path, prefix,  outfile):
	try:
		fds = []
		fout = open(outfile, 'a')
		for i in range(len(servers)):
			tfd = open(path + "/" + prefix+".result_" + servers[i])
			fds.append(tfd)
		ftexts = []
		isfirst = False
		for i in range(len(fds)):
			text = fds[i].readlines()
			for j in range(len(text)):
				text[j] = text[j].replace("\n", "")
			ftexts.append(text)
		for j in range(len(ftexts[0])):
			cnt = 0
			total_qps = 0.0
			total_lantency = 0.0
			total_p99layntency = 0.0
			for i in range(len(ftexts)):
				if j == 0 and i == 0:
					isfirst = True
					break
				isfirst = False
				arr = ftexts[i][j].split(',')
				cnt = int(arr[0])
				total_qps += float(arr[1])
				total_lantency += float(arr[2])
				total_p99layntency += float(arr[3])
			if isfirst == False:
				print >> fout, "%d,%0.2f,%0.2f,%0.2f" %(cnt,total_qps,(total_lantency/len(servers)),(total_p99layntency/len(servers)))
	finally:
		for fd in fds:
			fd.close()
		fout.close()

class MailUtil:
    def __init__(self, config_file):
        config = ConfigParser()
        config.read(config_file)
        self.server = config.get("mail", "server")
        self.port = config.getint("mail", "port")
        self.from_addr = config.get("mail", "from")
        self.to_addrs = config.get("mail", "to").split(',')
        self.cc_addrs = config.get("mail", "cc").split(',')

    def __init__(self, server='mail.srv', port=25, from_addr='robot@xiaomi.com', to_addrs='qinzuoyan@xiaomi.com', cc_addrs=''):
        self.server = server
        self.port = port
        self.from_addr = from_addr
        self.to_addrs = to_addrs.split(',')
        self.cc_addrs = cc_addrs.split(',')

    def sendmail(self, subject, body, files=None):
        msg = MIMEMultipart()
        msg['From'] = self.from_addr
        msg['To'] = COMMASPACE.join(self.to_addrs)
        msg['CC'] = COMMASPACE.join(self.cc_addrs)
        msg['Date'] = formatdate(localtime=True)
        msg['Subject'] = subject
        msg.attach( MIMEText(body) )

        for f in files or []:
            part = MIMEBase('application', "octet-stream")
            part.set_payload( open(f,"rb").read() )
            Encoders.encode_base64(part)
            part.add_header('Content-Disposition', 'attachment; filename="%s"' % basename(f))
            msg.attach(part)

        smtp = SMTP(self.server, self.port)
        print "sending mail ..."
        smtp.sendmail(self.from_addr, self.to_addrs, msg.as_string())
        print "send mail done"
        smtp.close()

    def sendmaileasy(self, subject, body):
        msg = MIMEMultipart()
        msg['From'] = self.from_addr
        msg['To'] = COMMASPACE.join(self.to_addrs)
        msg['Date'] = formatdate(localtime=True)
        msg['Subject'] = subject
        msg.attach( MIMEText(body) )

        smtp = SMTP(self.server, self.port)
        print "sending mail ..."
        smtp.sendmail(self.from_addr, self.to_addrs, msg.as_string())
        print "send mail done"
        smtp.close()
