{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.readline;

  mkSetVariableStr = n: v:
    let
      mkValueStr = v:
        if v == true then
          "on"
        else if v == false then
          "off"
        else if isInt v then
          toString v
        else if isString v then
          v
        else
          abort ("values ${toPretty v} is of unsupported type");
    in "set ${n} ${mkValueStr v}";

  mkBindingStr = k: v: ''"${k}": ${v}'';

in {
  options.programs.readline = {
    enable = mkEnableOption "readline";

    bindings = mkOption {
      default = { };
      type = types.attrsOf types.str;
      example = literalExpression ''
        { "\\C-h" = "backward-kill-word"; }
      '';
      description = "Readline bindings.";
    };

    variables = mkOption {
      type = with types; attrsOf (either str (either int bool));
      default = { };
      example = { expand-tilde = true; };
      description = ''
        Readline customization variable assignments.
      '';
    };

    includeSystemConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include the system-wide configuration.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration lines appended unchanged to the end of the
        <filename>~/.inputrc</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.file.".inputrc".text = let
      configStr = concatStringsSep "\n"
        (optional cfg.includeSystemConfig "$include /etc/inputrc"
          ++ mapAttrsToList mkSetVariableStr cfg.variables
          ++ mapAttrsToList mkBindingStr cfg.bindings);
    in ''
      # Generated by Home Manager.

      ${configStr}
      ${cfg.extraConfig}
    '';
  };
}
