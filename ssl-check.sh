#Domain List, one name per line
sites="
facebook.com
www.saugatnepal.com.np
"

tmp=/tmp/cert-check.out
now=`date -d "$now" +%s`

for site in $sites
do
        if [[ $site == \#* ]]; then continue; fi

        printf %-30s "$site: "

        echo | openssl s_client -showcerts -servername $site -connect $site:443 2>/dev/null | openssl x509 -inform pem -noout -text > $tmp
        issuer=`grep 'Issuer:' $tmp`
        issuer=${issuer##*O=}
        issuer=${issuer%%,*}

        subject=`grep 'Subject:' $tmp`
        subject=${subject##*CN=}
        subject=${subject%%,*}

        if [[ $site == $subject ]] || [[ ".$site" == $subject ]]; then match=' '; else match='!'; fi

        expires=`grep 'Not After' $tmp`
        expires=`date '+%Y-%m-%d' -d "${expires#*:}"`
        epoch=`date -d "$expires" +%s`

        if [ $epoch -lt $now ]
        then
                left='EXPIRED'
        else
                days=$(( ($epoch - $now) / 86400 ))
                left="$days days"
        fi

        printf %1s $match
        printf %30s "$subject | "
        printf %10s "$expires | "
        printf %14s "$left | "
        echo " $issuer";
done
