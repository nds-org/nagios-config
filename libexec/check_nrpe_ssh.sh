#! /bin/bash         
# Author: Sven Schwedas <sven.schwedas@tao.at> for TAO Software
# Published under MIT license
 
function freeport () {
    # pick random port to keep collision chance minimal, ideally we don't want
    # to enter the loop at all
    pnum=$(shuf -i $(sed 's/\t/-/' /proc/sys/net/ipv4/ip_local_port_range) -n 1)
    while nc -z 127.0.0.1 $pnum; do
        let pnum++
    done
    echo $pnum
}

sshopts=''
user=$USER
debug=false
eargs=''
nrpe_port=5666

while getopts 'hH:p:c:U:vut:a:ln' opt; do
    case $opt in
    h)
        echo 'USAGE: check_nrpe_ssh -H host [-p nrpeport] -c cmd [-U sshuser] [-v] [-u] [-t timeout] [-a arg] [-l] [-n]'
        echo ''
        echo '-U  SSH user (ssh -l $sshuser)'
        echo '-v  Enables SSH verbose mode (ssh -v)'
        echo '-H, -p, -c, -u, -t, -a, -l, -n: See `check_nrpe -h`'
        echo 'Note that -n still has to be configured if necessary!'
        exit
        ;;
    l)
        /usr/local/nagios/libexec/ -l
        exit $?
        ;;
    H)
        host=$OPTARG
        ;;
    p)
        nrpe_port=$OPTARG
        ;;
    c)
        cmd=$OPTARG
        ;;
    U)
        user=$OPTARG
        ;;
    v)
        debug=true
        ;;
    u)
        eargs="$eargs -u"
        ;;
    t)
        eargs="$eargs -t $OPTARG"
        ;;
    a)
        eargs="$eargs -a $OPTARG"
        ;;
    n)
        eargs="$eargs -n"
    esac
done


# -f + ExitOn + sleep = ssh backgrounds after establishing a connection,
# autocloses after $sleep seconds (unless the port is still in use), or
# after the port is closed by consumer
port=$(freeport)
if $debug; then
    sshopts="-v"
    echo "Establishing SSH forwarding on ports $port:$nrpe_port to $user@$host"
fi
ssh -o 'ExitOnForwardFailure yes' $sshopts -l $user -fL $port:127.0.0.1:$nrpe_port $host 'sleep 5'

exec /usr/local/nagios/libexec/check_nrpe -H localhost -p $port -c $cmd $eargs
