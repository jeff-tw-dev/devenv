package main

import "fmt"

func main() {
    fmt.Println("Hello from Go!")
		sum := Add(2, 3)
		fmt.Println(sum)
}

func Add(a, b int) int {
    return a + b
}
