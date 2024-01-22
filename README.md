# Multithreaded TCP Server 

HP Assignement: PThreads

Build a multi-threaded server in C++, make use of PThreads for parallel programming.

Get started by forking this repo!

## Requirements
 - g++
 - GNU Make (4.2.1 or higher)
 - [ncat (7.80 or higher)](https://nmap.org/ncat)

## Protocol Definition

The protocol consists of a series of messages sent between the client and the server. Each message is a single line of text, terminated by a newline character. The client and server will exchange messages until the client sends an `END` message, at which point the server will close the connection.

The server will respond to each message with a single line of text, terminated by a newline character. The server will not send a response until it has received a complete message from the client.

The client will send one of the following messages to the server:
 - `READ <key>` - Read the value of the given key from the database.
 - `WRITE <key>:<value>` - Write the given key-value pair to the database.
 - `COUNT` - Count the number of key-value pairs in the database.
 - `DELETE <key>` - Delete the given key from the database.
 - `END` - End the connection.

The database is a simple key-value store. Each key is a string, and each value is an string. The database is initialized to an empty state when the server starts.
It may be implemented as a simple `std::map<std::string, std::string> KV_DATASTORE`, but the specifics are up to you.

## Sample Input & Output

### Write

Following is an example `tests/inputs/WRITE.txt` to write a key value pair to the database.

```bash
nc localhost 8080 < tests/inputs/WRITE.txt  # FIN
```

```txt
WRITE
Hello
:1234
END
```

### Read

Following is an example `tests/inputs/READ.txt` to read a key value pair from the database.

```bash
nc localhost 8080 < tests/inputs/READ.txt  # NULL if does not exist
```

```txt
READ
Hello
END
```

### Count

Following is an example `tests/inputs/COUNT.txt` where the client only sends the `COUNT` message to list the number of KV pairs in the database.

```bash
nc localhost 8080 < tests/inputs/COUNT.txt  # 0,1, etc.
```

```txt
COUNT
END
```

### Delete

Following is an example `tests/inputs/DELETE.txt` where the client only sends the `DELETE` message to list the number of KV pairs in the database.

```bash
nc localhost 8080 < tests/inputs/DELETE.txt  # FIN if key present, NULL otherwise
```

```txt
DELETE
Hello
END
```

### All Commands

Following is an example `tests/inputs/ALL.txt`. Consider we are starting from an empty database and this is the first client connecting to the server.

```bash
nc localhost 8080 < tests/inputs/ALL.txt  # 0,1, etc.
```


```txt
DELETE
Hello  # 1. Delete the Key Hello, (returns FIN because it was not present)
COUNT  # 2. Count the number of KV pairs (returns 0)
READ
Hello  # 3. Read the value of the Key Hello
WRITE
Hello
:1234  # 4. Write the KV pair Hello:1234
READ
Hello  # 5. Read the value of the Key Hello, (returns 1234)
COUNT  # 6. Count the number of KV pairs (returns 1)
END    # 7. End the connection
```

### Anti-Example

Following is an anti-example `tests/inputs/BROKEN.txt`. Here, the client has forgotten to send the `END` message. The server will wait forever for the `END` message, and the client will wait forever for the server's response to the `COUNT` message.

```txt
DELETE
Hello  # 1. Delete the Key Hello, (returns FIN because it was not present)
COUNT  # 2. Count the number of KV pairs (returns 0)
READ
Hello  # 3. Read the value of the Key Hello; the server will wait forever for the END message
```

## Running

To run serial version :
```bash
make serial
./bin/serial_server 8080
```

To run parallel version :
```bash
make parallel
./bin/parallel_server 8080
```

## Testing

To connect to the server
```
ncat localhost 8080 < tests/inputs/ALL.txt
```

Run the test cases
```
make test_serial
make test_parallel

# To run with logging enabled
ENABLE_LOGGING=1 make test_serial
ENABLE_LOGGING=1 make test_parallel
```

# FAQ

1. Port already in use. This may happen if the server was not closed properly and the port is still in use.

    Solution: Kill the process using the port
    ```bash
    sudo lsof -i :8080
    kill -9 <PID>
    ```
2. `nc: HTTP/1.1 400 Bad Request Connection: close.` This may happen if the server is not running or netcat is pointed at the wrong port.
    
        Solution: Start the server and make sure the port is correct.
        ```bash
        ./bin/serial_server 8080
        ```
