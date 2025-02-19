/*
   Onix Config Manager - Terraform Provider
   Copyright (c) 2018-2020 by www.gatblau.org

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software distributed under
   the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
   either express or implied.
   See the License for the specific language governing permissions and limitations under the License.

   Contributors to this project, hereby assign copyright in this code to the project,
   to be licensed under the same terms as the rest of the code.
*/

package main

import (
	. "github.com/gatblau/oxc"
	"github.com/hashicorp/terraform-plugin-sdk/helper/schema"
)

func LinkTypeAttributeDataSource() *schema.Resource {
	return &schema.Resource{
		Read: readLinkTypeAttr,

		Schema: map[string]*schema.Schema{
			"key": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
			"type": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
			"def_value": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
			"required": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
			},
			"regex": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
			"link_type_key": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"version": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"created": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"updated": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"changed_by": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
		},
	}
}

func readLinkTypeAttr(data *schema.ResourceData, meta interface{}) error {
	// get the Ox client
	c := meta.(Config).Client

	// read the tf data into an Link Type Attr
	linkTypeAttr := &LinkTypeAttribute{
		Key:         data.Get("key").(string),
		LinkTypeKey: data.Get("link_type_key").(string),
	}

	// get the restful resource
	linkTypeAttr, err := c.GetLinkTypeAttr(linkTypeAttr)

	// populate the tf resource data
	if err == nil {
		populateLinkTypeAttr(data, linkTypeAttr)
	}

	return err
}
