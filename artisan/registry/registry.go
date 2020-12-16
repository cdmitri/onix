/*
  Onix Config Manager - Artisan
  Copyright (c) 2018-2020 by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/
package registry

import "github.com/gatblau/onix/artisan/core"

// the interface implemented by a local registry
// creds = user[:pwd]
type Registry interface {
	Push(name *core.ArtieName, remote Backend, credentials string)
}
