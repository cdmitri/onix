/*
  Onix Config Manager - Http Server
  Copyright (c) 2018-2021 by www.gatblau.org
  Licensed under the Apache License, Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0
  Contributors to this project, hereby assign copyright in this code to the project,
  to be licensed under the same terms as the rest of the code.
*/

package httpserver

import (
	"context"
	"fmt"
	"github.com/gatblau/onix/oxlib/oxc"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
)

// WhitelistMiddleware blocks any IP that are not in the whitelist
func (s *Server) WhitelistMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// if a whitelist has been defined and the request IP is not in the list
		if s.Whitelist != nil && !s.Whitelist(*r, FindRealIP(r)) {
			// blocks the request and returns an unauthorised error
			http.Error(w, "sender not in whitelist, request blocked", 401)
			return
		}
		// Call the next handler, which can be another middleware in the chain, or the final handler.
		next.ServeHTTP(w, r)
	})
}

// LoggingMiddleware log http requests to stdout
func (s *Server) LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path, _ := url.PathUnescape(r.URL.Path)
		fmt.Printf("request from: %s %s %s\n", r.RemoteAddr, r.Method, path)
		requestDump, err := httputil.DumpRequest(r, true)
		if err != nil {
			log.Println(err)
		}
		log.Println(string(requestDump))
		// Call the next handler, which can be another middleware in the chain, or the final handler.
		next.ServeHTTP(w, r)
	})
}

// AuthenticationMiddleware determines if the request is authenticated
func (s *Server) AuthenticationMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// holds user principal
		var (
			user    *oxc.UserPrincipal
			matched bool
			err     error
		)
		// loop through specific authentication by URL path
		for urlPattern, authenticate := range s.Auth {
			// if the request URL match the authentication function pattern
			matched, err = regexp.Match(urlPattern, []byte(r.URL.Path))
			// regex error?
			if err != nil {
				// Write an error and stop the handler chain
				log.Printf("authentication function error: %s\n", err)
				http.Error(w, "Authentication Error", http.StatusInternalServerError)
				return
			}
			// if the regex matched the URL path
			if matched {
				// if we have an authentication function defined
				if authenticate != nil {
					// then try and authenticate using the specified function
					user = authenticate(*r)
					// if authentication fails the there is no user principal returned
					if user == nil {
						// Write an error and stop the handler chain
						http.Error(w, "Forbidden", http.StatusUnauthorized)
						return
					} else {
						// exit loop
						break
					}
				} else {
					break
				}
			}
		}
		// if not authenticated by a custom handler then use default handler
		if user == nil && !matched {
			// no specific authentication function matched the request URL, so tries
			// the default authentication function if it has been defined
			// if no function has been defined then do not authenticate the request
			if s.DefaultAuth != nil {
				// if no Authorization header is found
				if r.Header.Get("Authorization") == "" {
					// prompts a client to authenticate by setting WWW-Authenticate response header
					w.Header().Set("WWW-Authenticate", fmt.Sprintf(`Basic realm="%s"`, s.realm))
					w.WriteHeader(http.StatusUnauthorized)
					fmt.Printf("! unauthorised http request from: '%v'\n", r.RemoteAddr)
					return
				} else {
					// authenticate the request using the default handler
					user = s.DefaultAuth(*r)
					if user == nil {
						// if the authentication failed, write an error and stop the handler chain
						http.Error(w, "Forbidden", http.StatusForbidden)
						return
					}
				}
			}
		}
		// create a user context containing the user principal
		userContext := context.WithValue(r.Context(), "User", user)
		// create a shallow copy of the request with the user context added to it
		req := r.WithContext(userContext)
		// pass down the request to the next middleware (or final handler)
		next.ServeHTTP(w, req)
	})
}

// AuthorisationMiddleware authorises the http request based on the rights in user principal in the request context
func (s *Server) AuthorisationMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := GetUserPrincipal(r)
		// if no principal is found reject the request
		if user == nil || !user.Rights.RequestAllowed(s.realm, r) {
			w.WriteHeader(http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// Authorise handler functions using user principal access control lists
// wraps the authorization middleware to be used when wrapping specific handler functions
func (s *Server) Authorise(handler http.HandlerFunc) http.Handler {
	return handler
}
