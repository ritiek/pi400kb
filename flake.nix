{
  description = "Raw HID keyboard forwarder to turn the Pi 400 into a USB keyboard";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixos-hardware }: 
    let
      system = "aarch64-linux";
    in {
      nixosModules.pi400kb = { config, lib, pkgs, ... }: 
      let
        configuredPackage = pkgs.stdenv.mkDerivation {
          pname = "pi400kb";
          version = if self ? shortRev then self.shortRev else "dev";
          src = self;
          buildInputs = [ pkgs.cmake ];
          nativeBuildInputs = [ pkgs.libconfig ];
          cmakeFlags = [ "-D HOOK_PATH=./hook.sh" ]
            ++ lib.optional (config.services.pi400kb.keyboard.vendorID != null) "-D KEYBOARD_VID=${config.services.pi400kb.keyboard.vendorID}"
            ++ lib.optional (config.services.pi400kb.keyboard.productID != null) "-D KEYBOARD_PID=${config.services.pi400kb.keyboard.productID}"
            ++ lib.optional (config.services.pi400kb.keyboard.device != null) "-D KEYBOARD_DEV=${config.services.pi400kb.keyboard.device}"
            ++ lib.optional (config.services.pi400kb.mouse.vendorID != null) "-D MOUSE_VID=${config.services.pi400kb.mouse.vendorID}"
            ++ lib.optional (config.services.pi400kb.mouse.productID != null) "-D MOUSE_PID=${config.services.pi400kb.mouse.productID}"
            ++ lib.optional (config.services.pi400kb.mouse.device != null) "-D MOUSE_DEV=${config.services.pi400kb.mouse.device}";
          installPhase = ''
            install -Dm755 pi400kb $out/bin/pi400kb
            install -Dm755 ../hook.sh $out/bin/hook.sh
          '';
          # led0 is named as PWR in NixOS 24.11 and above.
          postFixup = ''
            substituteInPlace $out/bin/hook.sh --replace led0 PWR
          '';
        };
      in {
        options.services.pi400kb = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable the Raw HID keyboard forwarder to turn the Pi 400 into a USB keyboard service.";
          };
          keyboard = {
            vendorID = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Keyboard Vendor ID override.";
            };
            productID = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Keyboard Product ID override.";
            };
            device = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Keyboard device path override.";
            };
          };
          mouse = {
            vendorID = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Mouse Vendor ID override.";
            };
            productID = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Mouse Product ID override.";
            };
            device = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Mouse device path override.";
            };
          };
        };

        config = lib.mkIf config.services.pi400kb.enable {
          systemd.services.pi400kb = {
            enable = config.services.pi400kb.enable;
            description = "pi400kb USB OTG Keyboard & Mouse forwarding";
            serviceConfig = {
              ExecStart = "${configuredPackage}/bin/pi400kb";
              User = "root";
              Group = "root";
              Type = "simple";
              Restart = "on-failure";
              WorkingDirectory = "${configuredPackage}/bin";
            };
            wantedBy = [ "multi-user.target" ];
          };
          boot.kernelModules = lib.mkAfter [ "libcomposite" ];
          hardware.raspberry-pi."4".dwc2.enable = true;
        };
      };
    };
}
