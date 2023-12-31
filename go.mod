unigrep/go.sum                                                                                      0000644 0001750 0001750 00000001611 14461521042 013254  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 github.com/inancgumus/screen v0.0.0-20190314163918-06e984b86ed3 h1:fO9A67/izFYFYky7l1pDP5Dr0BTCRkaQJUG6Jm5ehsk=
github.com/inancgumus/screen v0.0.0-20190314163918-06e984b86ed3/go.mod h1:Ey4uAp+LvIl+s5jRbOHLcZpUDnkjLBROl15fZLwPlTM=
golang.org/x/crypto v0.11.0 h1:6Ewdq3tDic1mg5xRO4milcWCfMVQhI4NkqWWvqejpuA=
golang.org/x/crypto v0.11.0/go.mod h1:xgJhtzW8F9jGdVFWZESrid1U1bjeNy4zgy5cRr/CIio=
golang.org/x/exp v0.0.0-20230725093048-515e97ebf090 h1:Di6/M8l0O2lCLc6VVRWhgCiApHV8MnQurBnFSHsQtNY=
golang.org/x/exp v0.0.0-20230725093048-515e97ebf090/go.mod h1:FXUEEKJgO7OQYeo8N01OfiKP8RXMtf6e8aTskBGqWdc=
golang.org/x/sys v0.10.0 h1:SqMFp9UcQJZa+pmYuAKjd9xq1f0j5rLcDIk0mj4qAsA=
golang.org/x/sys v0.10.0/go.mod h1:oPkhp1MJrh7nUepCBck5+mAzfO9JrbApNNgaTdGDITg=
golang.org/x/term v0.10.0 h1:3R7pNqamzBraeqj/Tj8qt1aQ2HpmlC+Cx/qL/7hn4/c=
golang.org/x/term v0.10.0/go.mod h1:lpqdcUyK/oCiQxvxVrppt5ggO2KCZ5QblwqPnfZ6d5o=
                                                                                                                       unigrep/interface.txt                                                                               0000644 0001750 0001750 00000001121 14460352206 014621  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 What I want this interactive app to be able to do...


Print optins of the bash script to use
for example

"SELECT ONE
(1) - Twitter Grep
(2) - Manual
(3) - Help
(4) - Exit
Choice >"


if user inputs incorrect, it will clear the console and reprint the whole thing

after they pick an option, it will go into sub script
for example they chose twitter Grep

"Input the paths you would like to grep for on twitter then say DONE"
> path
> /path2
> DONE"

"Ok... Running Script... (prints the dots, then deletes them, then prints them again)"
^^ should run concurrently as the bash script executes                                                                                                                                                                                                                                                                                                                                                                                                                                               unigrep/main.go                                                                                     0000644 0001750 0001750 00000015647 14461614476 013430  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 package main

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
                                                                                         unigrep/scripts/                                                                                    0000755 0001750 0001750 00000000000 14461063324 013615  5                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 unigrep/scripts/grep4wl.sh                                                                          0000755 0001750 0001750 00000003422 14461543537 015552  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 #!/usr/bin/bash

search_files() {
    local pattern="$1"
    local search_path=$2
    grep -rlE "$pattern" $search_path
}

process_files() {
    local regex_filter="$1"
    shift  # Remove the first two arguments (the script file and regex filter) from the arguments list
    local files=("$@")  # Use the rest of the arguments as the list of files
    # Initialize a variable to store the result

    # Iterate over the list of files and process their contents, excluding the script file
    for file in "${files[@]}"; do
        if [ "$file" != "$script_file" ]; then
            # Process the file contents and add matching lines to the result variable
            while IFS= read -r line; do
                if [[ "$line" =~ $regex_filter ]]; then
                    echo $line >> $output_file
                fi
            done < "$file"
        fi
    done

}





# Default values for options
regex=$1
search_dir=$2
output_file=$3


# Shift the parsed options so that the remaining arguments (if any) are accessible as positional parameters
files=$(search_files "$regex" $search_dir)  # Capture the result returned by the function

positiveFiles=$(echo $files | wc -w)
echo "Found $positiveFiles files with lines matching your regex"
if [ $positiveFiles -eq 0 ]
then
    echo note: if you are having trouble constucting a regex pattern, see this https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions >&2
    echo SCRIPT DONE >&2
    exit 0
fi
echo If there are a lot of lines matching your regex, this will take a while >&2

echo Processing the files
#echo lines will be instantly written to the output file, so you may quit early
echo > $output_file
process_files "$regex" $files

echo -e Done, wrote $(cat $output_file | wc -l) lines to $output_file
echo SCRIPT DONE

                                                                                                                                                                                                                                              unigrep/scripts/exec.sh                                                                             0000755 0001750 0001750 00000000221 14461613332 015073  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 #!/usr/bin/bash


outfile=$1
shift
echo $@
echo Adding $# lines to $outfile

for line in $@
do
    echo $line >> $outfile 
done

echo SCRIPT DONE                                                                                                                                                                                                                                                                                                                                                                               unigrep/script.txt                                                                                  0000644 0001750 0001750 00000000411 14460364656 014202  0                                                                                                    ustar   arthur                          arthur                                                                                                                                                                                                                 scripts should output data to some type of file or port that golang can listen for messages on


MANUAL
users enter paths
program keeps asking for paths
user says "DONE"
paths stop getting added to wordlist
then the user gets the option to go back or run the script                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       