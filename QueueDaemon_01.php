#!/usr/bin/php56
<?php

  var_dump($argv);
  if (isset($argv) && !empty($argv) && is_array($argv)) {
      if (in_array('--pidfile', $argv)) {
          $handle = array_search('--pidfile', $argv);
          $pidfile = $argv[intval($handle)+1];
          defined('LOCK_FILE') || define('LOCK_FILE', $pidfile);
      }
  }

  defined('LOCK_FILE') || define('LOCK_FILE', "/var/run/" . basename($argv[0], ".php") . ".pid");
//  if(!tryLock(LOCK_FILE)) {
//    die("Already running.\n");
//  }

  function tryLock($pidfile='')
  {
      global $argv;
      if (empty($pidfile)) {
          echo(__line__.' '.getmypid()."\n");
          $pidfile=basename($argv[0], ".php") . ".pid";
      }
      # If pid file exists, check if stale.  If exists and is not stale, return TRUE
      # Else, create lock file and return FALSE.

      # the @ in front of 'symlink' is to suppress the NOTICE you get if the LOCK_FILE exists
      if (@symlink("/proc/" . getmypid(), LOCK_FILE) !== false) {
          return true;
      }
      # link already exists
      # check if it's stale
      if (is_link(LOCK_FILE) && !file_exists(LOCK_FILE)) {
          unlink(LOCK_FILE);
          # try to lock again
          return tryLock($pidfile);
      }
      return false;
  }

  $sleepTime = 10; // number of second between runs
  $log = '/var/log/k2c/daemon.log';
  $cmd = 'cd '.dirname(__FILE__).' && /usr/bin/php56 queue.php -q all -v';
  /**
   * Method for displaying the help and default variables.
  **/
  function displayUsage()
  {
      global $log;

      echo "\n";
      echo "Process for spawning a PHP daemon.\n";
      echo "\n";
      echo "Usage:\n";
      echo "\tQueueDaemon.php [options]\n";
      echo "\n";
      echo "\toptions:\n";
      echo "\t\t--help display this help message\n";
      echo "\t\t--log=<filename> The location of the log file (default '$log')\n";
      echo "n";
  }//end displayUsage()

  //configure command line arguments
  if ($argc > 0) {
      foreach ($argv as $arg) {
          $args = explode('=', $arg);
          switch ($args[0]) {
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
  if ($pid == -1) {
      file_put_contents($log, "Error: could not daemonize process.\n", FILE_APPEND);
      return 1; //error
  } elseif ($pid) {
      return 0; //success
  } else {
      file_put_contents($log, date('Y/m/d H:i:s').' Successfully forked PHP into main process, Entering main loop...'."\n", FILE_APPEND);
      echo(__line__.' '.getmypid()."\n");
      if (!tryLock(LOCK_FILE)) {
          die("Already running.\n");
      }
      $report = true;
      //the main process
      while (true) {
          if ($report) {
              file_put_contents($log, date('Y/m/d H:i:s').' K2C Queue builder Daemonized and running...'."\n", FILE_APPEND);
              $report = false;
          }
          if (file_exists('/var/run/rcron/state') && strpos(file_get_contents('/var/run/rcron/state'), 'active') !== false) {
              shell_exec($cmd);
          } elseif (!file_exists('/var/run/rcron/state')) {
              shell_exec($cmd);
          }
          sleep($sleepTime);
      }//end while
  }//end if
?>

