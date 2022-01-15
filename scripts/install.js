const readline = require('readline');
const { exec } = require("child_process");
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });



console.log("Welcome to Deploy-Next Autoconfiguration");
console.log("--------------------------------------");

exec("git status", (err, stdout, stderr) => {
	if (err) {
		console.log(err);
		process.exit(1);
	}
	console.log(stdout);
});


rl.question("asdasd", (answer) =>
{
	console.log(`Your answer was ${ answer }`);
	rl.close();
});

rl.question("asdasd", (answer) =>
{
	console.log(`Your answer was ${ answer }`);
	rl.close();
});