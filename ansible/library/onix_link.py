#!/usr/bin/python
#
# Onix - Copyright (c) 2018 gatblau.org
# Apache License Version 2 - https://www.apache.org/licenses/LICENSE-2.0
#
# Module: onix_link
# Description: creates a new or updates an existing link between two existing configuration items
#
from ansible.module_utils.basic import *
from ansible.module_utils.urls import *

def createOrUpdateLink(data):
    # parse the input variables
    cmdb_host = data['cmdb_host']
    access_token = data['access_token']
    key = data['key']
    description = data['description']
    meta = data['meta']
    role = data['role']
    tag = data['tag']
    parent = data['parent']
    child = data['child']

    payload = {
        "description": description,
        "meta": meta,
        "tag": tag,
        "start_item_key": parent,
        "end_item_key": child,
        "role": role
    }

    if access_token == "":
        # if not access token is provided do not send it to the service
        headers = {"Content-Type": "application/json"}
    else:
        # if an access token exists then add it to the request headers
        headers = {"Content-Type": "application/json", "Authorization": "bearer {}".format(access_token)}

    payloadStr = json.dumps(payload).replace('"{','{').replace('}"', '}').replace('\'', '\"')

    # use line below for testing posting payload
    # link_uri = "https://httpbin.org/put"

    # builds the URI required by the cmdb service
    link_uri = "{}/link/{}/".format(cmdb_host, key)

    # put the payload to the cmdb service
    stream = open_url(link_uri, method="PUT", data=payloadStr, headers=headers)

    # reads the returned stream
    result = json.loads(stream.read())

    has_changed = True

    return (has_changed, result)

# module entry point
def main():
    has_changed = False

    params = {
        "cmdb_host": {"required": True, "type": "str"},
        "access_token": {"required": False, "type": "str", "default": "", "no_log": True},
        "key": {"required": True, "type": "str"},
        "description": {"required": False, "type": "str", "default": ""},
        "parent": {"required": True, "type": "str"},
        "child": {"required": True, "type": "str"},
        "role": {"required": True, "type": "str"},
        "meta": {"required": False, "type": "str", "default": "{}"},
        "tag": {"required": False, "type": "str", "default": ""}
    }

    # handle incoming parameters
    module = AnsibleModule(
        argument_spec = params,
        supports_check_mode = False
    )

    has_changed, result = createOrUpdateLink(module.params)

    # exit the module with a result (changed & meta json object)
    module.exit_json(
        changed = has_changed,
        meta = result
    )

if __name__ == '__main__':
    main()
