/*
  Onix Config Manager - Artisan
  Copyright (c) 2018-Present by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/
package tkn

type Pipeline struct {
	APIVersion string    `yaml:"apiVersion,omitempty"`
	Kind       string    `yaml:"kind,omitempty"`
	Metadata   *Metadata `yaml:"metadata,omitempty"`
	Spec       *Spec     `yaml:"spec,omitempty"`
}

type TaskRef struct {
	Name string `yaml:"name,omitempty"`
}

type Tasks struct {
	Name      string     `yaml:"name,omitempty"`
	TaskRef   *TaskRef   `yaml:"taskRef,omitempty"`
	Resources *Resources `yaml:"resources,omitempty"`
}
