let
  makeScxLavdTest = name: getKernelPackages: description:
    import ./make-test-python.nix ({ pkgs, ... }: {
      inherit name;
      
      meta = {
        maintainers = with pkgs.lib.maintainers; [ ];
      };

      nodes.machine = {
        boot.kernelPackages = getKernelPackages pkgs;
        
        services.scx = {
          enable = true;
          scheduler = "scx_lavd";
          package = pkgs.scx.lavd; # Use our standalone crates.io package
        };

        # Enable some debugging for scheduler validation
        boot.kernel.sysctl = {
          "kernel.sched_debug" = 1;
        };

        # Ensure we have some load for the scheduler to handle
        systemd.services.test-workload = {
          description = "CPU workload for scheduler testing";
          serviceConfig = {
            Type = "exec";
            ExecStart = "${pkgs.bash}/bin/bash -c 'for i in {1..4}; do ${pkgs.coreutils}/bin/yes > /dev/null & done; wait'";
            Restart = "no";
          };
        };
      };

      testScript = ''
        import time

        def wait_for_scheduler():
            """Wait for scx_lavd to attach and become active"""
            machine.wait_for_unit("scx.service")
            
            # Wait for scheduler process to appear
            machine.wait_until_succeeds("ps aux | grep -v grep | grep scx_lavd")
            
            # Give scheduler time to fully initialize
            time.sleep(5)

        def test_scheduler_attachment():
            """Verify scx_lavd has successfully attached to kernel"""
            # Check service is running
            machine.succeed("systemctl is-active scx.service")
            
            # Verify scx_lavd process is running
            machine.succeed("pgrep -f scx_lavd")
            
            # Check process is running as expected user
            machine.succeed("ps -U root -u root u | grep scx_lavd")

        def test_scheduler_functionality():
            """Test basic scheduler functionality under load"""
            # Start our test workload
            machine.succeed("systemctl start test-workload")
            
            # Scheduler should handle the load without issues
            time.sleep(10)
            
            # Verify scheduler is still active and handling processes
            machine.succeed("ps aux | grep -v grep | grep scx_lavd")
            
            # Stop the workload
            machine.succeed("systemctl stop test-workload")

        def test_service_management():
            """Test start/stop/restart of scx service"""
            # Test restart
            machine.succeed("systemctl restart scx.service")
            time.sleep(3)
            machine.succeed("systemctl is-active scx.service")
            
            # Test stop
            machine.succeed("systemctl stop scx.service")
            machine.wait_until_fails("pgrep -f scx_lavd")
            
            # Test start
            machine.succeed("systemctl start scx.service")
            machine.wait_until_succeeds("pgrep -f scx_lavd")

        def test_graceful_shutdown():
            """Ensure scheduler shuts down cleanly"""
            machine.succeed("systemctl stop scx.service")
            
            # Verify no zombie processes
            machine.wait_until_fails("pgrep -f scx_lavd")
            
            # Check no scheduler-related errors in journal
            machine.succeed("! journalctl -u scx.service --since='5 minutes ago' | grep -i 'error\\|failed\\|panic'")

        # Main test sequence
        print("Testing scx_lavd on " + "${description}")
        
        machine.start()
        machine.wait_for_unit("multi-user.target")

        with subtest("Scheduler attachment"):
            wait_for_scheduler()
            test_scheduler_attachment()

        with subtest("Scheduler functionality under load"):
            test_scheduler_functionality()

        with subtest("Service management"):
            test_service_management()

        with subtest("Graceful shutdown"):
            test_graceful_shutdown()

        print("scx_lavd test completed successfully on " + "${description}")
      '';
    });
in
{
  # Test on default kernel (minimum required: 6.12)
  default = makeScxLavdTest "scx_lavd_default" (pkgs: pkgs.linuxPackages) "default kernel (6.12 LTS)";
  
  # Test on latest kernel
  latest = makeScxLavdTest "scx_lavd_latest" (pkgs: pkgs.linuxPackages_latest) "latest kernel (6.16)";
}