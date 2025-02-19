/*
  Onix Config Manager - Artisan
  Copyright (c) 2018-Present by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/

package export

import "testing"

func TestSaveImage(t *testing.T) {
	if err := ExportImage("postgres:13", "postgres:13", "s3://localhost:9000/app1/v1", "user:pwd"); err != nil {
		t.Fatal(err)
	}
}
