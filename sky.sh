#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Gost - 基于Go语言的代理
#	Version: 1.0.0
#	Author: fly97
#=================================================

sh_ver="1.0.0"
shell_url="https://raw.githubusercontent.com/wf09/gost/master/sky.sh"
file="/usr/local/gost"
gost_file="/usr/local/gost/gost"
gost_conf="/usr/local/gost/config.json"
gost_log="/tmp/gost.log"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=$(uname -m)
}
check_installed_status(){
	[[ ! -e ${gost_file} ]] && echo -e "${Error} gost 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef | grep gost | grep -v grep | awk '{print $2}')
}
check_new_ver(){
	gost_new_ver=$( wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/ginuerzh/gost/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g;s/v//g')
	gost_new_vver='v'$gost_new_ver
	if [[ -z ${gost_new_ver} ]]; then
		echo -e "${Error} gost 最新版本获取失败，请手动获取最新版本号[ https://github.com/ginuerzh/gost/releases ]"
		read -e -p "请输入版本号 [ 格式 x.x.xx , 如 2.10.0 ] :" gost_new_ver
		[[ -z "${gost_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} gost 目前最新版本为 ${gost_new_ver}"
	fi
}
check_ver_comparison(){
	gost_now_ver=$(${gost_file} -V)
	if [[ ${gost_now_ver} != ${gost_new_ver} ]]; then
		echo -e "${Info} 发现 gost 已有新版本 [ ${gost_new_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[ -z "${yn}" ] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] &&	{PID}
			rm -rf ${gost_file}
				
			Start_gost
		fi
	else
		echo -e "${Info} 当前 gost 已是最新版本 [ ${gost_now_ver} ]" && exit 1
	fi
}
Download_gost(){
	cd ${file}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -O gost.gz "https://github.com/ginuerzh/gost/releases/download/${gost_new_vver}/gost-linux-amd64-${gost_new_ver}.gz"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		wget --no-check-certificate -O gost.gz "https://github.com/ginuerzh/gost/releases/download/${gost_new_vver}/gost-linux-386-${gost_new_ver}.gz"
	else
		echo "该系统不支持..." && exit 1
	fi
	[[ ! -e "gost.gz" ]] && echo -e "${Error} Gost 下载失败 !" && exit 1
	gzip -d gost.gz
	[[ ! -e ${gost_file} ]] && echo -e "${Error} Gost 解压失败(可能是 压缩包损坏 或者 没有安装 Gzip) !" && exit 1
	rm -rf gost.gz
	chmod +x gost
}
Service_gost(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/service/cloudt_centos" -O /etc/init.d/cloudt; then
			echo -e "${Error} Cloud Torrent服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/cloudt
		chkconfig --add cloudt
		chkconfig cloudt on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/wf09/gost/master/gost_service" -O /etc/init.d/gost; then
			echo -e "${Error} Cloud Torrent服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/gost
		update-rc.d -f gost defaults
	fi
	echo -e "${Info} Gost服务 管理脚本下载完成 !"
}
Installation_dependency(){
	gzip_ver=$(gzip -V)
	if [[ -z ${gzip_ver} ]]; then
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install -y gzip
		else
			apt-get update
			apt-get install -y gzip
		fi
	fi
	[[ ! -e ${file} ]] && mkdir ${file}
}
Write_config(){
	cat > ${gost_conf}<<-EOF
{
    "Debug": false,
    "Retries": 0,
    "ServeNodes": [
        "${gost_Protocol}://:${gost_port}"
    ]
}
EOF
}
Read_config(){
	[[ ! -e ${gost_conf} ]] && echo -e "${Error} Gost 配置文件不存在 !" && exit 1
	#gost_Protocol=`cat ${gost_conf}|grep "gost_Protocol = "|awk -F "gost_Protocol = " '{print $NF}'`
	#gost_port=`cat ${gost_conf}|grep "gost_port = "|awk -F "gost_port = " '{print $NF}'`
	# user=`cat ${gost_conf}|grep "user = "|awk -F "user = " '{print $NF}'`
	# passwd=`cat ${gost_conf}|grep "passwd = "|awk -F "passwd = " '{print $NF}'`
	clear && echo "===================================================" && echo
	echo -e " Gost账号 配置信息：" && echo
	echo -e " I  P\t:${Red_font_prefix} ${gost_ip} ${Font_color_suffix}"
	echo -e " 端口\t:${Red_font_prefix} ${gost_port} ${Font_color_suffix}"
	echo -e " 协议\t:${Red_font_prefix} ${gost_Protocol} ${Font_color_suffix}"
}
Set_ip(){
	gost_ip=$(curl -s -4 ip.sb)
	echo && echo "========================"
	echo -e "	IP : ${Red_background_prefix} ${gost_ip} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_port(){
	while true
		do
		echo -e "请输入端口 [1-65535]（如果是绑定的域名，那么建议80端口）"
		read -e -p "(默认端口: 443):" gost_port
		[[ -z "${gost_port}" ]] && gost_port="443"
		echo $((${gost_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${gost_port} -ge 1 ]] && [[ ${gost_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${gost_port} ${Font_color_suffix}"
				echo "========================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
}
# Set_user(){
	# echo "请输入 Gost 用户名"
	# read -e -p "(默认用户名: user):" ct_user
	# [[ -z "${ct_user}" ]] && ct_user="user"
	# echo && echo "========================"
	# echo -e "	用户名 : ${Red_background_prefix} ${ct_user} ${Font_color_suffix}"
	# echo "========================" && echo

	# echo "请输入 Cloud Torrent 用户名的密码"
	# read -e -p "(默认密码: 随机生成10位数字+字母):" ct_passwd
	# [[ -z "${ct_passwd}" ]] && ct_passwd=$(date +%s%N | md5sum | head -c 10)
	# echo && echo "========================"
	# echo -e "	密码 : ${Red_background_prefix} ${ct_passwd} ${Font_color_suffix}"
	# echo "========================" && echo
# }
Set_gost_Protocol(){
	echo -e "请选择 GOST支持的协议类型(Protocol)
	
 ${Green_font_prefix} 1.${Font_color_suffix} tcp
 
 ${Green_font_prefix} 2.${Font_color_suffix} http
 ${Green_font_prefix} 3.${Font_color_suffix} http2
 ${Green_font_prefix} 4.${Font_color_suffix} socks5 
 
 ${Green_font_prefix} 5.${Font_color_suffix} tls
 ${Green_font_prefix} 6.${Font_color_suffix} mtls
 ${Green_font_prefix} 7.${Font_color_suffix} socks5+tls"
	read -e -p "(默认: socks5+tls):" gost_Protocol
	[[ -z "${gost_Protocol}" ]] && gost_Protocol="7"
	if [[ ${gost_Protocol} == "1" ]]; then
		gost_Protocol="tcp"
	elif [[ ${gost_Protocol} == "2" ]]; then
		gost_Protocol="http"
	elif [[ ${gost_Protocol} == "3" ]]; then
		gost_Protocol="http2"
	elif [[ ${gost_Protocol} == "4" ]]; then
		gost_Protocol="socks5"
	elif [[ ${gost_Protocol} == "5" ]]; then
		gost_Protocol="tls"
	elif [[ ${gost_Protocol} == "6" ]]; then
		gost_Protocol="mtls"
	else
		gost_Protocol="socks5+tls"
	fi
	echo && echo ${Separator_1} && echo -e "协议类型 : ${Green_font_prefix}${gost_Protocol}${Font_color_suffix}" && echo ${Separator_1} && echo
} 
Set_conf(){
	Set_ip
	Set_port
	Set_gost_Protocol
	# read -e -p "是否设置 用户名和密码 ? [y/N] :" yn
	# [[ -z "${yn}" ]] && yn="n"
	# if [[ ${yn} == [Yy] ]]; then
		# Set_user
	# else
		# ct_user="" && ct_passwd=""
	# fi
}
Set_gost(){
	check_installed_status
	check_sys
	check_pid
	Set_conf
	Read_config
	#Del_iptables
	Write_config
	#Add_iptables
	#Save_iptables
	Restart_gost
}
Install_gost(){
	check_root
	[[ -e ${gost_file} ]] && echo -e "${Error} 检测到 gost 已安装 !" && exit 1
	check_sys
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_gost
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_gost
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	# echo -e "${Info} 开始设置 iptables防火墙..."
	# Set_iptables
	# echo -e "${Info} 开始添加 iptables防火墙规则..."
	# Add_iptables
	# echo -e "${Info} 开始保存 iptables防火墙规则..."
	# Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_gost
	Read_config
}
Start_gost(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} gost 正在运行，请检查 !" && exit 1
	/etc/init.d/gost start
}
Stop_gost(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} gost 没有运行，请检查 !" && exit 1
	/etc/init.d/gost stop
}
Restart_gost(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/gost stop
	/etc/init.d/gost start
}
Log_gost(){
	[[ ! -e "${gost_log}" ]] && echo -e "${Error} gost 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${gost_log}${Font_color_suffix} 命令。" && echo
	tail -f "${gost_log}"
}
Update_gost(){
	check_installed_status
	check_sys
	check_new_ver
	check_ver_comparison
	/etc/init.d/gost start
}
Uninstall_gost(){
	check_installed_status
	echo "确定要卸载 gost ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		#Read_config
		#Del_iptables
		#Save_iptables
		rm -rf ${file} && rm -rf /etc/init.d/gost
		rm $gost_log
		# if [[ ${release} = "centos" ]]; then
			# chkconfig --del cloudt
		# else
		update-rc.d -f gost remove
		# fi
		echo && echo "gost 卸载完成 !"
	else
		echo && echo "卸载已取消..."
	fi
}
View_gost(){
	check_installed_status
	#Read_config
	host=$(curl -s -4 ip.sb)
	port=${gost_port}
	echo -e " 你的 Gost 信息:" && echo
	cat $gost_conf
	# if [[ -z ${user} ]]; then
		# clear && echo "————————————————" && echo
		# echo -e " 你的 gost 信息 :" && echo
		# echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		# echo && echo "————————————————"
	# else
		# clear && echo "————————————————" && echo
		# echo -e " 你的 Cloud Torrent 信息 :" && echo
		# echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		# echo -e " 用户\t: ${Green_font_prefix}${user}${Font_color_suffix}"
		# echo -e " 密码\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
		# echo && echo "————————————————"
	# fi
}
# Add_iptables(){
	# iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ct_port} -j ACCEPT
	# iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ct_port} -j ACCEPT
	# iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	# iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	# iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	# iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
# }
# Del_iptables(){
	# iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	# iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	# iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	# iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	# iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	# iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
# }
# Save_iptables(){
	# if [[ ${release} == "centos" ]]; then
		# service iptables save
	# else
		# iptables-save > /etc/iptables.up.rules
	# fi
# }
# Set_iptables(){
	# if [[ ${release} == "centos" ]]; then
		# service iptables save
		# chkconfig --level 2345 iptables on
	# else
		# iptables-save > /etc/iptables.up.rules
		# echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		# chmod +x /etc/network/if-pre-up.d/iptables
	# fi
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "${shell_url}" |grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/gost" ]]; then
		rm -rf /etc/init.d/gost
		Service_gost
	fi
	wget -N --no-check-certificate ${shell_url} && chmod +x sky.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}


Del_log(){
	[[ ! -e ${gost_log} ]] && echo -e "${Error} Gost 日志文件不存在 !" && exit 1
	rm -rf ${gost_log}
	if [[ ! -e ${gost_log} ]] ;then
		echo -e "${Info} Gost 日志已删除！"
	fi
}
main(){
	echo && echo -e "Gost 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}	
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
 
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Gost
 ${Green_font_prefix}2.${Font_color_suffix} 升级 Gost
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 Gost
 
 ${Green_font_prefix}4.${Font_color_suffix} 启动 Gost
 ${Green_font_prefix}5.${Font_color_suffix} 停止 Gost
 ${Green_font_prefix}6.${Font_color_suffix} 重启 Gost
 
 ${Green_font_prefix}7.${Font_color_suffix} 设置 Gost 账号
 ${Green_font_prefix}8.${Font_color_suffix} 查看 Gost 账号
 ${Green_font_prefix}9.${Font_color_suffix} 查看 Gost 日志
 ${Green_font_prefix}10.${Font_color_suffix} 删除 Gost 日志 
————————————" && echo
	if [[ -e ${gost_file} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
	echo
	read -e -p " 请输入数字 [0-9]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Install_gost
		;;
		2)
		Update_gost
		;;
		3)
		Uninstall_gost
		;;
		4)
		Start_gost
		;;
		5)
		Stop_gost
		;;
		6)
		Restart_gost
		;;
		7)
		Set_gost
		;;
		8)
		View_gost
		;;
		9)
		Log_gost
		;;
		10)
		Del_log
		;;
		*)
		echo "请输入正确数字 [0-9]"
		;;
	esac
}
main