package main

import (
	"bufio"
	"fmt"
	"github.com/SupremeERG/colorPrint"
	"github.com/SupremeERG/opshins"
	"github.com/inancgumus/screen"
	"golang.org/x/exp/slices"
	"log"
	"os/exec"
	"sync"
	"time"
)

func clearConsole() {
	screen.Clear()
	screen.MoveTopLeft()
}

// this is what chatgpt told me
func runBashScript(scriptPath string, arguments []string, outputChan chan<- string, errOutputChan chan<- string) {
	defer close(outputChan)
	defer close(errOutputChan)
	cmdArgs := append([]string{scriptPath}, arguments...)
	cmd := exec.Command("bash", cmdArgs...)

	stdout, stdoutpipeErr := cmd.StdoutPipe()
	if stdoutpipeErr != nil {
		log.Println("Error creating stdout pipe:", stdoutpipeErr)
		return
	}
	stderr, stderrpipeErr := cmd.StderrPipe()
	if stderrpipeErr != nil {
		log.Println("Error creating stdout pipe: ", stderrpipeErr)
		return
	}

	if err := cmd.Start(); err != nil {
		log.Println("Error starting command:", err)
		return
	}

	scanner := bufio.NewScanner(stdout)
	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			output := scanner.Text()
			outputChan <- output // Send the output to the channel
		}
	}()

	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			output := scanner.Text()
			errOutputChan <- output // Send the output to the channel
		}
	}()

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading stdout:", err)
	}

	cmd.Wait()
}

func displayOutput(outputChan <-chan string, stderrOutputChan <-chan string) {

	go func() {
		for output := range outputChan {
			fmt.Print(colorPrint.Color("blue", "[*] "))
			colorPrint.Reset()
			fmt.Println(output) // Display the output
			if output == "SCRIPT DONE" {
				return
			}
		}
	}()

	go func() {
		for output := range stderrOutputChan {
			fmt.Print(colorPrint.Color("red", "[*] "))
			colorPrint.Reset()
			fmt.Println(output)
			if output == "SCRIPT DONE" {
				return
			}
		}
	}()
}

func printMainScreen() (string, []string) {
	options := []string{"Fetch", "Manual", "grep4wl", "Help", "Exit"}
	optionsNum := []string{"1", "2", "3", "4", "5"}
	fmt.Println("Welcome\nHere are your options")
	//fmt.Print(colorPrint.Color("blue", "(1)"))
	for i := 0; i < len(options); i++ {
		// fmt.Printf("(%s) - %s\n", string(i), options[i])
		str := fmt.Sprintf("(%d) ", i+1)
		fmt.Print(colorPrint.Color("blue", str))
		colorPrint.Reset()
		fmt.Println(" - " + options[i])
	}
	fmt.Print(colorPrint.Color("green", " > "))
	colorPrint.Reset()
	var choice string
	fmt.Scan(&choice)
	return choice, optionsNum
}

func getCmdArgs(script string, arguments *[]string) []string {

	if script == "exec" {
		var outputFile string
		var askOutFile func()
		askOutFile = func() {
			fmt.Print("Enter the output file to write to" + colorPrint.Color("green", " > "))
			fmt.Scan(&outputFile)
			colorPrint.Reset()
			askRegexAnswer := opshins.PromptYN("Are you sure this is output file you want to write to?", "yes", colorPrint.Color("green", " > "+colorPrint.Default()))
			if askRegexAnswer == "no" {
				askOutFile()
			}
		}
		askOutFile()

		*arguments = append(*arguments, outputFile)
		entries := opshins.WhilePrompt("Enter a line", "DONE", colorPrint.Color("green", " > " + colorPrint.Default()))
		*arguments = append(*arguments, entries...)
		return *arguments
	} else if script == "grep4wl" {
		var regex string
		var dir string
		var output string
		var askRegex func()
		var askDirectory func()
		var askOutFile func()
		askRegex = func() {
			fmt.Print("Enter the regex you would like to use" + colorPrint.Color("green", " > "))
			fmt.Scan(&regex)
			colorPrint.Reset()
			askRegexAnswer := opshins.PromptYN("Are you sure this is the regex you want to use?", "yes", colorPrint.Color("green", " > "+colorPrint.Default()))
			if askRegexAnswer == "no" {
				askRegex()
			}
		}
		askRegex()

		askDirectory = func() {
			fmt.Print("enter the directory to grep through" + colorPrint.Color("green", " > "))
			fmt.Scan(&dir)
			colorPrint.Reset()
			askDirectoryAnswer := opshins.PromptYN("Are you sure this is the directory you want to search?", "yes", colorPrint.Color("green", " > "+colorPrint.Default()))
			if askDirectoryAnswer == "no" {
				askDirectory()
			}

		}
		askDirectory()

		askOutFile = func() {
			fmt.Print("Enter the output file [overwrites existing files]" + colorPrint.Color("green", " > "))
			fmt.Scan(&output)
			colorPrint.Reset()
			askOutFileAnswer := opshins.PromptYN("Are you sure this is the file you want to write to?", "yes", colorPrint.Color("green", " > "+colorPrint.Default()))
			if askOutFileAnswer == "no" {
				askOutFile()
			}

		}
		askOutFile()

		return []string{regex, dir, output}

	} else {
		return []string{"blah"}
	}
}

func main() {
	var wg sync.WaitGroup
	// take an argument for the output file, if no arg file given, quit
	clearConsole()
	log.SetPrefix("unigrep: ")
	log.SetFlags(0)
	time.Sleep(1)
	choice, options := printMainScreen()
	if slices.Contains(options, choice) == false {
		clearConsole()
		fmt.Println("[-] The option you chose was incorrect")
		fmt.Println("[-] Please choose the corresponding number to an option")
		time.Sleep(3000 * time.Millisecond)
		main()
	}

	switch choice {
	case "1":
		fmt.Println("selected fetch")
	case "2":
		script := "exec"
		outputChan := make(chan string)
		stderrOutputChan := make(chan string)

		clearConsole()
		fmt.Println(colorPrint.Color("white", "MANUAL WLUPDATE"))
		colorPrint.Reset()
		fmt.Print(colorPrint.Color("blue", "[*] "))
		colorPrint.Reset()
		fmt.Println("Add lines to your wordlist (useless, im deleting this)")

		wg.Add(2) // Add a wait group counter for the bash script goroutine

		func() { // running script
			arguments := getCmdArgs(script, &[]string{})

			go func() {
				fmt.Println("Press CTRL+C to stop the script")
				runBashScript("scripts/exec.sh", arguments, outputChan, stderrOutputChan)
				wg.Done() // Mark the goroutine as done when the bash script finishes
			}()

			go func() {
				displayOutput(outputChan, stderrOutputChan)
				wg.Done()
			}()

			wg.Wait() // Wait until the bash script finishes before prompting for user input
			//fmt.Scanln()
		}()
	case "3":
		script := "grep4wl"
		outputChan := make(chan string)
		stderrOutputChan := make(chan string)

		clearConsole()
		fmt.Println(colorPrint.Color("white", "grep4wl"))
		colorPrint.Reset()
		fmt.Print(colorPrint.Color("blue", "[*] "))
		colorPrint.Reset()
		fmt.Println("Extract from wordlists in your filesystem")

		wg.Add(2) // Add a wait group counter for the bash script goroutine

		func() { // running script
			arguments := getCmdArgs(script, &[]string{})

			go func() {
				fmt.Println("Press CTRL+C to stop the script")
				runBashScript("scripts/grep4wl.sh", arguments, outputChan, stderrOutputChan)
				wg.Done() // Mark the goroutine as done when the bash script finishes
			}()

			go func() {
				displayOutput(outputChan, stderrOutputChan)
				wg.Done()
			}()

			wg.Wait() // Wait until the bash script finishes before prompting for user input
			//fmt.Scanln()
		}()
	case "4":
		log.Fatal("Exiting")
	}

}
