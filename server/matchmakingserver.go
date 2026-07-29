package main

import (
	"fmt"
	"net/http"
	"strconv"
	"time"
)

type Server struct {
	port     int
	region   string
	count    int
	game_map string
	updated  time.Time
}

var servers []Server

// Handle the request when each game server instance send a http request for joining the game
func serverHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		fmt.Println(err)
		return
	}

	// Receive and parse the data
	var receivedPort int
	var receivedRegion string
	var receivedCount int
	var receivedMap string
	receivedPort, _ = strconv.Atoi(r.FormValue("port"))
	receivedRegion = r.FormValue("region")
	receivedCount, _ = strconv.Atoi(r.FormValue("count"))
	receivedMap = r.FormValue("map")
	updated := time.Now()

	var found bool = false
	for index, _ := range servers {
		// Finding the occurence of this server, if they exist then update current value instead
		if servers[index].port == receivedPort {
			fmt.Println("Replacing current value ", receivedPort, updated.Format("00:00:00"))
			servers[index].port = receivedPort
			servers[index].region = receivedRegion
			servers[index].count = receivedCount
			servers[index].game_map = receivedMap
			servers[index].updated = updated
			found = true
		}
	}
	if !found {
		appended := false
		for index, _ := range servers {
			// Check for any unclaimed positions and replace to that instead
			if servers[index].port == -1 {
				servers[index].port = receivedPort
				servers[index].region = receivedRegion
				servers[index].count = receivedCount
				servers[index].game_map = receivedMap
				servers[index].updated = updated
				appended = true
			}
		}
		if !appended {
			// Add new value to the server
			var server Server
			server.port = receivedPort
			server.region = receivedRegion
			server.count = receivedCount
			server.game_map = receivedMap
			server.updated = updated

			servers = append(servers, server)
		}

		fmt.Println("Adding new value", receivedPort, receivedRegion, receivedCount)
	}

	fmt.Println(r.Form)
}

// Send a response to client for the servers available to connect, the port to connect, current player count and region (currently only asia region exist)
func clientHandler(w http.ResponseWriter, r *http.Request) {
	var text string
	text += "Number of servers is " + strconv.Itoa(len(servers)) + ";"
	for _, value := range servers {
		// Port of -1 mean the server is invalidated
		if value.port != -1 {
			text += strconv.Itoa(value.port) + ","
			text += value.region + ","
			text += strconv.Itoa(value.count) + ","
			text += value.game_map + ","
		}
	}
	fmt.Fprintf(w, text)
}

func main() {
	// Handle request from server on a different goroutine
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/server", serverHandler)
		mux.HandleFunc("/connect", clientHandler)
		// Choose this port just for abitrary reason
		http.ListenAndServe(":55144", mux)
	}()
	fmt.Println("Next thread")
	ticker := time.NewTicker(1 * time.Minute)
	for {
		select {
		case <-ticker.C:
			for index, _ := range servers {
				fmt.Println("Check current server: ", servers[index].port, servers[index].region, servers[index].count)
				// If has not received an update in a minute from now, the server will be removed from the mm server. Will be cleaned instead of removed and free a slot
				if servers[index].updated.Add(5 * time.Minute).Before(time.Now()) {
					servers[index].port = -1
				}
			}
		}
	}

}
