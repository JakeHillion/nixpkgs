{ lib
, python3
, fetchFromGitHub
 }:

python3.pkgs.buildPythonApplication rec {
  pname = "virtme-ng";
  version = "1.32";

  src = fetchFromGitHub {
    owner = "arighi";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-NB6nNNa3l2jSWiAAMdGLDPJYn+83Feifk6TgBJD7ULQ=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    argcomplete
    requests
    setuptools
  ] ++ (with pkgs; [
    file
    qemu
    socat
  ]);
}
