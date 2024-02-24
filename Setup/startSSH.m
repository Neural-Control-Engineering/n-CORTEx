host = "128.59.87.69"
username = "user"
password = "2photon"
ssh_conn = ssh2_config(host, username, password)
var = 3;
ssh2_command(ssh_conn,sprintf("connected! disp(%d)",var));
ssh2_command(ssh_conn,'DISPLAY=:0 matlab');
ssh2_command(ssh_conn, "matlab.apputil.run('C:\Code_Repo\nCORTEx\nCORTEx_extraction')",1)
ssh2_command()