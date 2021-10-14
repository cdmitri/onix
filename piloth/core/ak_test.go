/*
  Onix Config Manager - Pilot
  Copyright (c) 2018-2021 by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/

package core

import (
	"fmt"
	"testing"
)

func TestLoadAK(t *testing.T) {
	ak, err := LoadAK()
	if err != nil {
		t.Errorf(err.Error())
	}
	fmt.Println(ak)
}
