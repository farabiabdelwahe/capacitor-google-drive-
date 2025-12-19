import { GoogleDrive } from 'ccapacitor-google-drive';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    GoogleDrive.echo({ value: inputValue })
}
