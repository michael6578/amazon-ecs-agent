#!/bin/bash
# Copyright 2014-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the
# "License"). You may not use this file except in compliance
#  with the License. A copy of the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and
# limitations under the License.

export VERSION=$(cat $(dirname "${0}")/../VERSION)

export IMAGE_TAG_LATEST="latest"
export IMAGE_TAG_SHA=$(git rev-parse --short=8 HEAD)
export IMAGE_TAG_VERSION="v${VERSION}"

export IMAGE_TAG_LATEST_ARM="arm64-latest"
export IMAGE_TAG_SHA_ARM="arm64-$(git rev-parse --short=8 HEAD)"
export IMAGE_TAG_VERSION_ARM="arm64-v${VERSION}"

export IMAGE_TAG_LATEST_AMD="amd64-latest"
export IMAGE_TAG_SHA_AMD="amd64-$(git rev-parse --short=8 HEAD)"
export IMAGE_TAG_VERSION_AMD="amd64-v${VERSION}"

SUPPORTED_OSES=("linux" "windows")

supported_os() {
	local os=$1
	for entry in ${SUPPORTED_OSES[@]} ; do
		test "${os}" == "${entry}" && return $(true)
	done
	return $(false)
}

dryval() {
	case ${DRYRUN} in
	true)
		echo "DRYRUN: ${@}" 1>&2
		;;
	false)
		echo "RUNNING: ${@}" 1>&2
		"${@}"
		;;
	*)
		echo "invalid DRYRUN flag"
		;;
	esac
}

check_md5() {
	test_md5="$(md5sum ${1} | sed 's/ .*//')"
	expected_md5="$(cat ${2})"
	if [ ! "${test_md5}" = "${expected_md5}" ]; then
		echo "Computed md5sum ${test_md5} did not match expected md5sum ${expected_md5}"
		return $(false)
	fi

	return $(true)
}



tag_and_push_docker() {
	if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
		return
	fi

	IMAGE_NAME=${1}
	IMAGE_TAG=${2}

	echo "Tagging as ${IMAGE_NAME}:${IMAGE_TAG}"
	docker tag amazon/amazon-ecs-agent:latest "${IMAGE_NAME}:${IMAGE_TAG}"
	echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG}"
	dryval docker push "${IMAGE_NAME}:${IMAGE_TAG}"
}

s3_ls() {
	profile=""
	if [[ ! -z "${AWS_PROFILE}" ]]; then
		profile="--profile=${AWS_PROFILE}"
	fi
	aws ${profile} s3 ls "${1}"
}

s3_rm() {
	profile=""
	if [[ ! -z "${AWS_PROFILE}" ]]; then
		profile="--profile=${AWS_PROFILE}"
	fi
	echo "Removing ${1}"
	aws ${profile} s3 rm "${1}"
}

s3_cp() {
	profile=""
	if [[ ! -z "${AWS_PROFILE}" ]]; then
		profile="--profile=${AWS_PROFILE}"
	fi
	acl="public-read"
	if [[ ! -z "${S3_ACL_OVERRIDE}" ]]; then
		acl="${S3_ACL_OVERRIDE}"
	fi
	echo "Copying ${1} to ${2}"
	aws ${profile} s3 cp "${1}" "${2}" "--acl=${acl}"
}
