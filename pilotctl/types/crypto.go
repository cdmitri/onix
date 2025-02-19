package types

/*
  Onix Config Manager - Pilot Control
  Copyright (c) 2018-2021 by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/gatblau/onix/artisan/core"
	"github.com/gatblau/onix/artisan/crypto"
	"os"
	"path/filepath"
)

// Sign create a cryptographic signature for the passed-in object
func sign(obj interface{}) (string, error) {
	// only sign if we have an object
	if obj != nil {
		// load the signing key
		path, err := KeyFilePath("sign")
		if err != nil {
			return "", err
		}
		// retrieve the verification key from the specified location
		pgp, err := crypto.LoadPGP(path, "")
		if err != nil {
			return "", fmt.Errorf("sign => cannot load signing key: %s", err)
		}
		// obtain the object checksum
		cs, err := checksum(obj)
		if err != nil {
			return "", fmt.Errorf("sign => cannot create checksum: %s", err)
		}
		signature, err := pgp.Sign(cs)
		if err != nil {
			return "", fmt.Errorf("sign => cannot create signature: %s", err)
		}
		// return a base64 encoded string with the digital signature
		return base64.StdEncoding.EncodeToString(signature), nil
	}
	return "", nil
}

// checksum create a checksum of the passed-in object
func checksum(obj interface{}) ([]byte, error) {
	source, err := json.Marshal(obj)
	if err != nil {
		return nil, fmt.Errorf("checksum => cannot convert object to JSON to produce checksum: %s", err)
	}
	// indent the json to make it readable
	dest := new(bytes.Buffer)
	err = json.Indent(dest, source, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("checksum => cannot indent JSON to produce checksum: %s", err)
	}
	// create a new hash
	hash := sha256.New()
	// write object bytes into hash
	_, err = hash.Write(dest.Bytes())
	if err != nil {
		return nil, fmt.Errorf("checksum => cannot write JSON bytes to hash: %s", err)
	}
	// obtain checksum
	sum := hash.Sum(nil)
	return sum, nil
}

// KeyFilePath return the path to the file where the relevant PGP key is
// keyType is either verify (public) or sign (private) PGP key
func KeyFilePath(keyType string) (string, error) {
	name := fmt.Sprintf(".pilot_%s.pgp", keyType)
	path := filepath.Join(executablePath(), name)
	_, err := os.Stat(path)
	if err != nil {
		path = filepath.Join(homePath(), name)
		_, err = os.Stat(path)
		if err != nil {
			// TODO: make path OS agnostic
			path = fmt.Sprintf("/keys/%s", name)
			_, err = os.Stat(path)
			if err != nil {
				return "", fmt.Errorf("cannot find %s key\n", keyType)
			}
		}
		return path, nil
	}
	return path, nil
}

func receiverConfigFile() string {
	filename := "ev_receive.json"
	path := filepath.Join(executablePath(), filename)
	_, err := os.Stat(path)
	if err != nil {
		path = filepath.Join(homePath(), filename)
		_, err = os.Stat(path)
		if err != nil {
			path = fmt.Sprintf("/conf/%s", filename)
			_, err = os.Stat(path)
			if err != nil {
				path, err := core.AbsPath(filename)
				if err != nil {
					return ""
				}
				return path
			}
		}
		return path
	}
	return path
}

func executablePath() string {
	ex, err := os.Executable()
	if err != nil {
		panic(err)
	}
	return filepath.Dir(ex)
}

func homePath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	return home
}
