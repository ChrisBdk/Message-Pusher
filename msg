#!/usr/bin/env bash
###############################################################################
[[ -v DEBUG ]] && shopt -so xtrace || shopt -so errexit nounset pipefail

###[ CONSTRUCT ]###############################################################
declare -l class=$(readlink -f ${BASH_SOURCE} || echo ${BASH_SOURCE})
declare -g funcs="${class##*/}::main \${FUNCNAME##*:} \"\${@}\""
declare -a types=( none fail okay warn info dbug note text )
declare -A helps=(
	[ink]="'\E[m\E[1;%dm' \$((\${1-} + 30))" [dot]="'.'" [ret]="'\n'"
	[msg]="'\E[10G%s' \"\${@}\"" [box]="'\E[0G'['\E[%dG']'\E[m' 8"
	[tag]="'\E[3G%s\E[m' \${1-}"
)
declare -l type help

###[ CONSTANTS ]###############################################################
declare -r CLASS=${class##*/}
declare -a MSGTAGS

###[ MESSAGE HOOKS ]###########################################################
for type in ${types[@]}
do source <(echo "function ${class##*/}::${type} { ${funcs} ;}")
	MSGTAGS+=( ${type} )
done

###[ HELPER HOOKS ]############################################################
for help in ${!helps[@]}
do funcs="printf ${helps[${help}]}"
	source <(echo "function ${class##*/}::echo::${help} { ${funcs} ;}")
	declare ${help^^}=true
done

###[ CLEANING ]################################################################
unset class type types funcs help helps

###[ WRITER ]##################################################################
function msg::echo {
	declare -a echos=( box ink tag msg dot ret )
	declare -u var
	for var in ${echos[@]}
	do  [[ -v ${var} ]] && ${FUNCNAME}::${var,,} "${!var}"
	done
}
###[ MAIN FUNCTION ]###########################################################
function msg::main {
	declare -i len=${#MSGTAGS[@]}
	TAG=${1:-${MSGTAGS}}
	MSG="${@}"
	INK=7

	for ((i = (len - 1); i > 0; --i))
	do  [[ ${TAG} != ${MSGTAGS[${i}]} ]] || break
	done

	MSG="${MSG/#${TAG} }"
	TAG=${TAG^^}

	[[ -v ${TAG}_INK ]] || INK=${i}
	[[ ${TAG} != ${MSG^^} ]] || MSG='...'
	[[ ${TAG} != text ]] || unset BOX TAG

	${CLASS}::echo
}

###[ MAIN WRAPPER ]############################################################
function main {
	if [[ ${CLASS} != ${BASH_SOURCE##*/} ]]
	then  ${CLASS}::${BASH_SOURCE##*/} "${@}"
	else  ${CLASS}::${FUNCNAME} "${@}"
	fi
}

###[ HANDELER ]################################################################
[[ ${BASH_SOURCE} != ${0} ]] && unset -f main || main "${@}"
