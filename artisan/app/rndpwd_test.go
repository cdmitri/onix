/*
  Onix Config Manager - Artisan
  Copyright (c) 2018-Present by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/

package app

import (
	"fmt"
	"testing"
)

func TestNewPwd(t *testing.T) {
	fmt.Println(RandomPwd(55, false))
	fmt.Println(RandomPwd(36, true))
}
