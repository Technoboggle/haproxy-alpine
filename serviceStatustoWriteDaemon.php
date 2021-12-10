[root@cs2001 system]# cat /var/www/omni/cron/v03/serviceStatustoWriteDaemon.php
#!/usr/bin/php
<?php
  $sleepTime = 10; // number of second between runs
  $log = '/var/log/k2c/daemon.log';
  $cmd = 'cd '.dirname(__FILE__).' && /usr/bin/php serviceStatustoWrite.php';
  /**
   * Method for displaying the help and default variables.
  **/
  function displayUsage(){
    global $log;

    echo "\n";
    echo "Process for spawning a PHP daemon.\n";
    echo "\n";
    echo "Usage:\n";
    echo "\tserviceStatustoWriteDaemon.php [options]\n";
    echo "\n";
    echo "\toptions:\n";
    echo "\t\t--help display this help message\n";
    echo "\t\t--log=<filename> The location of the log file (default '$log')\n";
    echo "n";
  }//end displayUsage()

  //configure command line arguments
  if($argc > 0){
    foreach($argv as $arg){
      $args = explode('=',$arg);
      switch($args[0]){
        case '--help':
          return displayUsage();
        case '--log':
          $log = $args[1];
        break;
      }//end switch
    }//end foreach
  }//end if

  //fork the process to work in a daemonized environment
  file_put_contents($log, "Status: starting up.\n", FILE_APPEND);
  $pid = pcntl_fork();
  if($pid == -1){
    file_put_contents($log, "Error: could not daemonize process.\n", FILE_APPEND);
    return 1; //error
  } elseif($pid) {
    return 0; //success
  } else{
    file_put_contents($log, date('Y/m/d H:i:s').' Successfully forked PHP into main process, Entering main loop...'."\n", FILE_APPEND);
    $report = TRUE;
    //the main process
    while(true){
      if($report) {
        file_put_contents($log, date('Y/m/d H:i:s').' K2C Service Status builder Daemonized and running...'."\n", FILE_APPEND);
        $report = FALSE;
      }
      if(file_exists('/var/run/rcron/state') && strpos(file_get_contents('/var/run/rcron/state'),'active') !== false ) {
        shell_exec($cmd);
      } elseif(!file_exists('/var/run/rcron/state')){
        shell_exec($cmd);
      }
      sleep($sleepTime);
    }//end while
  }//end if
?>
[root@cs2001 system]#
