figlet "Let's Install kubeadm Cluster"

multipass delete --all ; multipass purge

multipass launch -n kmaster -c 2 -m 2G ; multipass transfer kmaster.sh kmaster:/tmp ; multipass exec kmaster -- sudo sh /tmp/kmaster.sh

echo -e "sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no `multipass info kmaster | grep -i ipv4 | awk '{ print $2; }'`:/joincluster.sh /joincluster.sh 2>/dev/null" >> kworker.sh
echo -e "bash /joincluster.sh >/dev/null 2>&1" >> kworker.sh

multipass launch -n kworker -c 2 -m 2G ; multipass transfer kworker.sh kworker:/tmp ; multipass exec kworker -- sudo sh /tmp/kworker.sh