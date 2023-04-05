build:
	# 替换_posts/2023目录下的所有原始资源前缀
	sed -i "" "s/\.\.\/\.\.\/assets/http:\/\/beangogo\.cn\/assets/g" `grep -rlI "../../assets" "_posts/2023"`
