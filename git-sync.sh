while true
do
	echo "#--------------------------------"
	echo `date`
	git add . 
	git commit -m update
	git push
	sleep 5m
done 